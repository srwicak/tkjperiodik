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
    # Tentukan template berdasarkan tipe user dan usia
    template_filename = determine_template(score)
    template_path = Rails.root.join("private/assets/templates", template_filename)

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

  def determine_template(score)
    registration = score.registration
    user = registration.user
    user_detail = user.user_detail
    
    # Hitung usia berdasarkan tanggal ujian
    exam_date = registration.exam_session.start_time.to_date
    birth_date = user_detail.date_of_birth
    age = exam_date.year - birth_date.year
    age -= 1 if exam_date < birth_date + age.years
    
    # Tentukan tipe (polisi atau pns) berdasarkan user type atau identity format
    is_police = user.identity.match?(/^\d{8}$/) # NRP 8 digit
    
    # Pilih template
    if is_police
      age >= 51 ? "hasil-51-nrp.pdf" : "hasil-50-nrp.pdf"
    else
      age >= 51 ? "hasil-51-nip.pdf" : "hasil-50-nip.pdf"
    end
  end

  def generate_qr_pdf(qr_io, score)
    pdf = Prawn::Document.new(margin: 0, page_size: "LEGAL")

    # Ambil data peserta
    registration = score.registration
    user = registration.user
    user_detail = user.user_detail
    
    name = user_detail.name
    position = user_detail.position
    unit = user_detail.unit
    rank = user_detail.rank
    identity = user.identity
    golongan = registration.golongan
    
    # Tentukan keterangan golongan usia (sesuai formulir pendaftaran)
    golongan_text = case golongan
    when 1
      "I (Usia 18 s.d 30 Tahun)"
    when 2
      "II (Usia 31 s.d 40 Tahun)"
    when 3
      "III (Usia 41 s.d 50 Tahun)"
    when 4
      "IV (Usia 51 Tahun Keatas)"
    else
      "-"
    end
    
    # Tentukan apakah usia 51+ (untuk template yang tidak ada nilai B)
    exam_date = registration.exam_session.start_time.to_date
    birth_date = user_detail.date_of_birth
    age = exam_date.year - birth_date.year
    age -= 1 if exam_date < birth_date + age.years
    is_51_plus = age >= 51

    # Parse data nilai dari score_detail
    data_nilai = JSON.parse(score.score_detail)
    score_data = data_nilai["score"]
    
    # Nilai A: score lari_12_menit
    nilai_a = score_data["lari_12_menit"].to_f
    
    # Nilai B: rata-rata 4 item setelah lari (hanya untuk usia < 51)
    if is_51_plus
      nilai_b = nil # Tidak ada nilai B untuk usia 51+
    else
      chinning = score_data["chinning"].to_f
      sit_ups = score_data["sit_ups"].to_f
      push_ups = score_data["push_ups"].to_f
      shuttle_run = score_data["shuttle_run"].to_f
      nilai_b = ((chinning + sit_ups + push_ups + shuttle_run) / 4).round(2)
    end
    
    # Nilai akhir
    nilai_akhir_angka = score.score_number.to_f
    nilai_akhir_grade = score.score_grade
    nilai_akhir = "#{nilai_akhir_angka} (#{nilai_akhir_grade})"

    # Ambil semester dan tahun dari nama ujian
    exam_name = score.registration.exam_session.exam.name
    
    # Coba parse berbagai format nama ujian
    # Format 1: "TKJ PERIODIK SEMESTER II TAHUN 2025"
    # Format 2: "SEMESTER I T.A. 2024" atau "SEMESTER II TAHUN 2024"
    # Format 3: "Semester 1 TA 2025"
    match = exam_name.match(/[Ss]emester\s+([IVXLCDM]+|\d+).*?[Tt]ahun(?:\s+[Aa]nggaran)?\s*(\d{4})/)
    
    if match
      semester_raw = match[1]
      tahun = match[2]
      
      # Konversi angka ke romawi jika perlu
      semester = case semester_raw.upcase
      when '1', 'I' then 'I'
      when '2', 'II' then 'II'
      when '3', 'III' then 'III'
      when '4', 'IV' then 'IV'
      else semester_raw
      end
    else
      # Fallback jika tidak bisa parse
      semester = "-"
      tahun = Date.today.year.to_s
    end
    
    # Buat judul periode tes lengkap
    periode_tes = "Periode Tes: Semester #{semester} Tahun #{tahun}"

    times_path = Rails.root.join("private", "assets", "fonts", "times.ttf")

    pdf.font_families.update("Times" => {
      normal: times_path,
      bold: times_path,
      italic: times_path,
      bold_italic: times_path,
    })
    pdf.font "Times"

    # Judul Periode Tes (center atas)
    # Kertas LEGAL width = 612 points, height = 1008 points
    pdf.text_box periode_tes, 
      at: [0, 844],
      width: 612,
      height: 50,
      size: 14,
      align: :center
    
    # Gabungkan rank dan identity dalam satu baris (format: PANGKAT NRP/NIP 12345678)
    rank_identity_combined = "#{rank}/#{identity}"

    # TODO: Sesuaikan koordinat dengan template PDF yang baru
    # Ini adalah contoh, perlu disesuaikan dengan posisi field di template
    pdf.text_box name, at: [146, 812], size: 12
    pdf.text_box position, at: [146, 788], size: 12
    pdf.text_box rank_identity_combined, at: [146, 764], size: 12
    pdf.text_box unit, at: [146, 740], size: 12
    pdf.text_box golongan_text, at: [422, 740], size: 12

    # Data nilai
    pdf.text_box nilai_a.to_s, at: [500, 638], size: 12
    
    # Nilai B dan koordinat nilai akhir berbeda untuk usia < 51 vs 51+
    if nilai_b
      # Usia < 51: Ada Nilai A, B, dan Nilai Akhir
      pdf.text_box nilai_b.to_s, at: [500, 608], size: 12
      pdf.text_box nilai_akhir, at: [500, 580], size: 12 # Koordinat untuk template < 51
    else
      # Usia 51+: Hanya Nilai A dan Nilai Akhir (koordinat nilai akhir lebih tinggi)
      pdf.text_box nilai_akhir, at: [500, 608], size: 12 # Koordinat untuk template 51+
    end

    
    # Simpan sementara QR sebagai file PNG
    image_file = Tempfile.new(["qr", ".png"])
    image_file.binmode.write(qr_io.read)
    image_file.rewind

    # Tempelkan image ke posisi tertentu
    pdf.image image_file.path, at: [22, 500], width: 80

    image_file.close
    image_file.unlink

    CombinePDF.parse(pdf.render)
  end
end
