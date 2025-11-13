class GenerateResultReportJob < ApplicationJob
  queue_as :default

  def perform(score_id)
    score = Score.find(score_id)
    # Set status processing
    score.update!(result_report_status: :processing)

    # Generate slug jika belum ada
    score.result_report_slug ||= Nanoid.generate(size: 10)
    score.save! if score.changed?

    # Buat URL QR dari slug
    qr_url = Rails.application.routes.url_helpers.result_report_slug_url(
      score.result_report_slug,
      host: "https://tkjperiodik.com" # ganti sesuai production host
    )

    # Generate QR PNG IO
    qr_png_io = generate_qr(qr_url)

    # Generate final PDF dengan QR ditempel
    final_pdf_io = generate_pdf_with_qr(qr_png_io, score)

    # Buat nama file
    filename = "hasil_#{score.registration.user.identity}_#{score.result_report_slug}.pdf"

    # Upload ke Shrine storage :store
    uploaded_file = ResultReportUploader.new(:store).upload(
      final_pdf_io,
      metadata: {
        filename: filename,
        content_type: "application/pdf"
      }
    )

    # Simpan hasil upload dan update status completed
    score.result_report = uploaded_file
    score.result_report_status = :completed
    score.save!
  rescue => e
    # Jika ada error, update status error dan log
    score.update(result_report_status: :error) if score.present?
    Rails.logger.error("GenerateResultReportJob failed for score_id=#{score_id}: #{e.message}\n#{e.backtrace.join("\n")}")
    raise e
  end

  private

  def generate_qr(url)
    qr = RQRCode::QRCode.new(url)
    png = qr.as_png(
      size: 200,
      border_modules: 0, # Hilangkan white space
      color: 'black',
      fill: 'white'
    )

    io = StringIO.new(png.to_s)
    io.rewind
    io
  end

  def generate_pdf_with_qr(qr_io, score)
    template_path = Rails.root.join("private/assets/templates/result_report_v2.pdf")

    # Load template PDF
    template_pdf = CombinePDF.load(template_path)

    # Generate halaman QR PDF
    qr_pdf = generate_qr_pdf(qr_io, score)

    # Tempelkan QR pada halaman pertama
    first_page = template_pdf.pages[0]
    first_page << qr_pdf.pages[0]

    # Kembalikan PDF sebagai StringIO
    io = StringIO.new(template_pdf.to_pdf)
    io.rewind
    io
  end

  def generate_qr_pdf(qr_io, score)
    pdf = Prawn::Document.new(page_size: "A4")

    # Konten
    data_nilai = JSON.parse(score.score_detail)
    grouped = Hash.new { |h, k| h[k] = [] } 
    data_nilai["score"].each do |key, value|
      person = key.split('_')[1] # ambil angka kedua, yaitu nomor orang
      grouped[person] << value.to_i
    end

    averages = grouped.transform_values do |scores|
      (scores.sum.to_f / scores.size).round(2)
    end

    nilai_akhir = "#{(averages.values.sum / averages.size).round(2)} / #{score.score_grade}"

    semester, tahun = score.registration.exam_session.exam.name.match(/SEMESTER\s+([IVXLCDM]+).*?(?:T\.A\.|TAHUN(?:\s+ANGGARAN)?)\s+(\d{4})/).captures
    user_detail = score.registration.user.user_detail
    name = user_detail.name
    unit = user_detail.unit
    position = user_detail.position
    rank = user_detail.rank
    identity = score.registration.user.identity

    arial_mt_path = Rails.root.join("private", "assets", "fonts", "arialmt.ttf")

    pdf.font_families.update("Arial MT" => {
      normal: arial_mt_path,
      bold: arial_mt_path,
      italic: arial_mt_path,
      bold_italic: arial_mt_path,
    })
    pdf.font "Arial MT"


    pdf.text_box semester, at: [302, 648], size: 9
    pdf.text_box tahun, at: [340, 648], size: 9
    pdf.text_box name, at: [60, 612], size: 9
    pdf.text_box position, at: [60, 598], size: 9
    pdf.text_box unit, at: [60, 584], size: 9
    pdf.text_box rank, at: [398, 612], size: 9
    pdf.text_box identity, at: [398, 598], size: 9

    pdf.text_box averages["1"].round(2).to_s, at: [438, 532], size: 9
    pdf.text_box averages["2"].round(2).to_s, at: [438, 514], size: 9
    pdf.text_box averages["3"].round(2).to_s, at: [438, 498], size: 9
    pdf.text_box nilai_akhir, at: [430, 480], size: 9

    
    # Simpan sementara QR sebagai file PNG
    image_file = Tempfile.new(["qr", ".png"])
    image_file.binmode.write(qr_io.read)
    image_file.rewind

    # Tempelkan image ke posisi tertentu
    pdf.image image_file.path, at: [-10, 460], width: 80

    image_file.close
    image_file.unlink

    CombinePDF.parse(pdf.render)
  end
end
