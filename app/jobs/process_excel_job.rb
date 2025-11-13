# app/jobs/process_excel_job.rb
class ProcessExcelJob < ApplicationJob
  queue_as :default

  # konstanta supaya gampang dirubah
  HEADER_ROW   = 0  # baris yang berisi judul
  COL_NRP      = 3  # indeks kolom NRP (0-based)
  COL_NILAI    = 5  # indeks kolom NILAI
  COL_KET      = 7  # indeks kolom KETERANGAN

  def perform(excel_upload)
    upload = excel_upload
    exam   = upload.exam
    upload.processing!

    workbook = RubyXL::Parser.parse(upload.file.download)
    sheet    = workbook[0]

    # 1. Ambil semua NRP dari baris data dan normalize dengan leading zeros
    raw_nrps = (HEADER_ROW + 1..sheet.sheet_data.rows.size - 1)
               .filter_map { |i| sheet[i][COL_NRP]&.value&.to_s&.strip }
               .compact

    # Normalize NRP: pastikan panjang 8 karakter dengan leading zeros
    normalized_nrps = raw_nrps.map { |nrp| nrp.rjust(8, '0') }

    # Log untuk debugging normalisasi NRP
    raw_nrps.zip(normalized_nrps).each do |raw, normalized|
      if raw != normalized
        Rails.logger.info "NRP normalized: #{raw} -> #{normalized}"
      end
    end

    # 2. Query score sekaligus - simpan data lengkap untuk memisahkan nilai dan keterangan
    scores_data = Score.joins(registration: [:user, :exam_session])
                       .where(users: { identity: normalized_nrps },
                              exam_sessions: { exam_id: exam.id })
                       .pluck('users.identity',
                              :score_grade,
                              :score_number)
                       .map { |nrp, grade, num| [nrp, { grade: grade, number: num }] }
                       .to_h
    
    # missing = nrps.reject { |n| scores_data.key?(n) }
    # Rails.logger.info "NRP dari Excel: #{normalized_nrps.inspect}"
    # Rails.logger.info "NRP ditemukan nilai: #{scores_data.keys.inspect}"
    # Rails.logger.info "NRP tidak ada nilai: #{missing.inspect}"

    # 3. Isi kolom NILAI (5) dan KETERANGAN (7)
    (HEADER_ROW + 1..sheet.sheet_data.rows.size - 1).each do |row_idx|
      raw_nrp = sheet[row_idx][COL_NRP]&.value&.to_s&.strip
      next if raw_nrp.blank?

      # Normalize NRP dengan leading zeros untuk pencarian
      normalized_nrp = raw_nrp.rjust(8, '0')
      
      if scores_data[normalized_nrp]
        score_info = scores_data[normalized_nrp]
        grade = score_info[:grade]
        number = score_info[:number]
        
        if grade.present? && number.present?
          # Ada nilai, masukkan ke kolom NILAI
          sheet.add_cell(row_idx, COL_NILAI, "#{grade}(#{number})")
          # Kosongkan kolom keterangan atau bisa diisi dengan "-"
          sheet.add_cell(row_idx, COL_KET, "-")
        else
          # Terdaftar tapi tidak ada nilai (tidak hadir)
          sheet.add_cell(row_idx, COL_NILAI, "-")
          sheet.add_cell(row_idx, COL_KET, "tidak hadir")
        end
      else
        # Tidak terdaftar sama sekali
        sheet.add_cell(row_idx, COL_NILAI, "-")
        sheet.add_cell(row_idx, COL_KET, "tidak daftar")
      end
    end

    # 4. Simpan file hasil
    tmp_path = Rails.root.join('tmp', "processed-#{upload.id}.xlsx")
    workbook.write(tmp_path)

    # Create a new file with proper filename and skip validation
    File.open(tmp_path, 'rb') do |file|
      upload.file_attacher.assign(
        file,
        metadata: { "filename" => "nilai-#{exam.name.parameterize}-#{upload.unit}.xlsx" }
      )
      upload.save!(validate: false)
    end
    
    upload.finished!

  rescue StandardError => e
    upload.error!
    # log / re-raise jika mau retry
    # Rails.logger.error("ProcessExcelJob #{upload.id}: #{e.message}")
    raise e
  ensure
    File.delete(tmp_path) if tmp_path && File.exist?(tmp_path)
  end
end