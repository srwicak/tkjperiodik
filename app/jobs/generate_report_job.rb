class GenerateReportJob < ApplicationJob
  queue_as :default

  def perform(score_id)
    score = Score.find_by(id: score_id)
    return unless score

    score.processing!

    registration = score.registration
    exam_session = registration.exam_session
    exam = exam_session.exam
    user_detail = registration.user.user_detail

    result_doc = exam.result_doc
    content = result_doc&.content ? JSON.parse(result_doc.content) : {}

    exam_name = content.dig('general', 'exam_name') || exam.name
    exam_name_short = content.dig('general', 'exam_name_short') || exam.name
    exam_name_other = content.dig('general', 'exam_name_other') || exam.name

    sk_number = content.dig('general', 'sk_number')
    sk_date = content.dig('general', 'sk_date')
    signer_name = content.dig('general', 'signer_name')
    signer_nrp = content.dig('general', 'signer_nrp')

    sk_unit = content.dig('units', user_detail.unit)

    unit_name = user_detail.formatted_unit
    unit_short = user_detail.unit.titlecase

    name = user_detail.name
    rank_identity = "#{user_detail.rank}/#{registration.user.identity}"
    unit = user_detail.unit
    if user_detail.gender
      gender = "PRIA"
    else
      gender = "WANITA"
    end

    results = "#{exam_name_short} : #{score.score_number.to_s.gsub('.', ',')} (#{score.score_grade})"

    notes = score.notes ? score.notes : "-"


    template_path = Rails.root.join("private", "assets", "templates", "dokumen_hasil_r9.docx").to_s
    output_path = Rails.root.join("tmp", "hasil_#{registration.user.identity}_#{SecureRandom.hex}.docx")

    unless File.exist?(template_path)
      Rails.logger.error "Template file not found: #{template_path}"
      score.error!
      return
    end


    begin
      # Buka dokumen template
      doc = Docx::Document.open(template_path)

      # Mengisi template dengan data di luar tabel
      doc.paragraphs.each do |p|
        p.each_text_run do |tr|
          tr.substitute('{{EXAM_NAME}}', exam_name)
          tr.substitute('{{EXAM_NAME_OTHER}}', exam_name_other)
          tr.substitute('{{SKPOLRI}}', sk_number) if sk_number.present?
          tr.substitute('{{SKPOLRI_DATE}}', sk_date) if sk_date.present?
          tr.substitute('{{SK_UNIT}}', sk_unit) if sk_unit.present?

          tr.substitute('{{UNIT_NAME}}', unit_name)
          tr.substitute('{{UNIT_SHORT}}', unit_short)
          tr.substitute('{{RANK_UP}}', user_detail.group)
        end
      end

      # Mengisi template dengan data di dalam tabel
      doc.tables.each do |table|
        table.rows.each do |row|
          row.cells.each do |cell|
            cell.paragraphs.each do |p|
              p.each_text_run do |tr|
                tr.substitute('{{NAME}}', name)
                tr.substitute('{{RANK_IDENTITY}}', rank_identity)
                tr.substitute('{{UNIT}}', unit)
                tr.substitute('{{GENDER}}', gender)
                tr.substitute('{{RESULT}}', results)
                tr.substitute('{{NOTES}}', notes)
                tr.substitute('{{SIGNNAME}}', signer_name) if signer_name.present?
                tr.substitute('{{NOMORREG}}', signer_nrp) if signer_nrp.present?
              end
            end
          end
        end
      end

      # Simpan hasilnya ke file baru
      doc.save(output_path)


      File.open(output_path) do |file|
        score.result_doc = file
      end

      if score.save
        score.completed!
      else
        puts "Errors: #{registration.errors.full_messages.join(', ')}"
        score.error!
      end

      #Clean up the temporary files
      File.delete(output_path) if File.exist?(output_path)
    rescue => e
      Rails.logger.error "Failed to process document: #{e.message}"
      score.error!
    end
  end
end
