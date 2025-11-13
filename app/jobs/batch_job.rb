require 'zip'

class BatchJob < ApplicationJob
  queue_as :default

  def perform(batch_id)
    batch = Batch.find(batch_id)
    return unless batch

    batch.processing!

    # Ambil semua registrasi yang sesuai dengan unit dan jenis pendaftaran
    registrations = Registration.joins(user: :user_detail, exam_session: :exam).joins(:score).where(
      exams: { id: batch.exam_id },
      registration_type: batch.registration_type,
      user_details: { unit: batch.unit }
    ).where.not(scores: { score_number: nil })

    total_participants = registrations.count
    batch.update!(total_count: total_participants)

    # Path template dokumen
    template_path = Rails.root.join("private", "assets", "templates", "dokumen_hasil_r9.docx").to_s
    temp_dir = Rails.root.join("tmp", "docx_temp_#{SecureRandom.hex}")

    # Membuat direktori sementara
    Dir.mkdir(temp_dir) unless Dir.exist?(temp_dir)

    # File output DOCX gabungan
    output_docx_path = Rails.root.join("tmp", "batch_#{batch.slug}_#{SecureRandom.hex}.docx")

    # Membuka file DOCX dan mengekstrak isinya menggunakan Rubyzip
    Zip::File.open(template_path) do |template|
      template.each do |entry|
        entry.extract(File.join(temp_dir, entry.name)) unless File.exist?(File.join(temp_dir, entry.name))
      end
    end

    registrations.each_with_index do |registration, index|
      # Buat dokumen berdasarkan template dan tambahkan konten peserta
      doc_file_path = generate_participant_docx(temp_dir, registration, index)

      # Gabungkan file ini ke dalam file gabungan
      append_docx_content(temp_dir, doc_file_path)
    end

    # Setelah semua peserta diproses, kompres kembali menjadi file DOCX
    Zip::File.open(output_docx_path, Zip::File::CREATE) do |zipfile|
      Dir[File.join(temp_dir, '**', '**')].each do |file|
        zipfile.add(file.sub("#{temp_dir}/", ''), file)
      end
    end

    # Simpan file gabungan ke Shrine dan update batch
    File.open(output_docx_path) do |file|
      batch.batch = file
      batch.completed!
    end

    # Hapus file sementara
    FileUtils.rm_rf(temp_dir)
    File.delete(output_docx_path) if File.exist?(output_docx_path)

  rescue => e
    Rails.logger.error "Failed to process batch: #{e.message}"
    batch.error!
  end

  private

  # Generate participant docx content
  def generate_participant_docx(temp_dir, registration, index)
    # Path file doc peserta sementara
    doc_path = File.join(temp_dir, "word", "document.xml")
    doc_content = File.read(doc_path)

    # Ambil data terkait peserta
    user_detail = registration.user.user_detail
    score = registration.score
    exam_name = registration.exam_session.exam.name
    signer_name = batch.signer_name
    unit_name = user_detail.unit
    name = user_detail.name
    score_number = score.score_number.to_s.gsub('.', ',')

    # Gantikan placeholder di XML
    doc_content.gsub!("{{NAME}}", name)
    doc_content.gsub!("{{SCORE}}", score_number)
    doc_content.gsub!("{{EXAM_NAME}}", exam_name)
    doc_content.gsub!("{{SIGNER_NAME}}", signer_name)
    doc_content.gsub!("{{UNIT_NAME}}", unit_name)

    # Simpan hasil ke file sementara
    File.write(doc_path, doc_content)

    # Return path dari file yang sudah di-generate
    File.join(temp_dir, "participant_#{index}.docx")
  end

  # Append content from one DOCX to another
  def append_docx_content(temp_dir, doc_file_path)
    main_doc_path = File.join(temp_dir, "word", "document.xml")
    participant_doc_path = File.join(temp_dir, "word", "participant.xml")

    # Baca konten file participant dan tambahkan ke file utama
    participant_content = File.read(participant_doc_path)
    main_content = File.read(main_doc_path)

    # Sisipkan konten baru dan pisahkan halaman jika perlu
    page_break = '<w:p><w:r><w:br w:type="page"/></w:r></w:p>'
    main_content << participant_content << page_break

    # Simpan kembali ke file XML utama
    File.write(main_doc_path, main_content)
  end
end
