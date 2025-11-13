class GeneratePdfJob < ApplicationJob
  queue_as :default

  def perform(registration_id)
    registration = Registration.find_by(id: registration_id)
    return unless registration

    return if registration.completed?

    registration.processing!

    user_detail = registration.user.user_detail
    name = user_detail.name
    rank_identity = "#{user_detail.rank}/#{registration.user.identity}"
    unit = user_detail.unit
    position = user_detail.position
    reg_type = "#{registration.registration_type.humanize.upcase}"
    created_at = "Daftar: #{I18n.l(registration.created_at, format: :default)} WIB"
    code = "Reg: #{registration.score.code[0, 3]}-#{registration.score.code[-4, 4]}"
    exam_session = "Sesi ujian: #{I18n.l(registration.exam_session.start_time, format: :simple_no_sec)} - #{I18n.l(registration.exam_session.end_time, format: :time_wib)}"

    # 2025 Update
    exam_name = registration.exam_session.exam.name

    # 2024 Version
    # template_path = Rails.root.join("private", "assets", "templates", "borang_pendaftaran_v3.pdf")
    
    # 2025 Update
    template_path = Rails.root.join("private", "assets", "templates", "borang_pendaftaran_v5.pdf")
    output_path = Rails.root.join("tmp", "pendaftaran_#{SecureRandom.hex}.pdf")

    unless File.exist?(template_path)
      Rails.logger.error "Template file not found: #{template_path}"
      registration.error!
      return
    end

    begin
      arial_narrow_path = Rails.root.join("private", "assets", "fonts", "arialnarrow.ttf")
      overlay_pdf_path = Rails.root.join("tmp", "overlay_#{SecureRandom.hex}.pdf")

      # 2024 version of the PDF generation
      # Prawn::Document.generate(overlay_pdf_path, margin: 0) do |pdf|
      #   pdf.font_families.update("Arial Narrow" => {
      #     normal: arial_narrow_path,
      #     bold: arial_narrow_path,
      #     italic: arial_narrow_path,
      #     bold_italic: arial_narrow_path,
      #   })
      #   pdf.font "Arial Narrow"
      #   pdf.text_box reg_type, at: [276, 858], size: 11
      #   pdf.text_box name, at: [256, 824], size: 11
      #   pdf.text_box rank_identity, at: [256, 807], size: 11
      #   pdf.text_box unit, at: [256, 790], size: 11
      #   pdf.text_box position, at: [256, 774], size: 11
      #   pdf.text_box created_at, at: [18, 60], size: 9
      #   pdf.text_box exam_session, at: [18, 50], size: 9
      #   pdf.text_box code, at: [18, 38], size: 11

      #   # 2025 Update
      #   pdf.text_box exam_name, at: [200, 842], size: 9
      # end
      # 
      
      # 2025 Update
      Prawn::Document.generate(overlay_pdf_path, margin: 0) do |pdf|
        pdf.font_families.update("Arial Narrow" => {
          normal: arial_narrow_path,
          bold: arial_narrow_path,
          italic: arial_narrow_path,
          bold_italic: arial_narrow_path,
        })
        pdf.font "Arial Narrow"
        pdf.text_box reg_type, at: [276, 858], size: 11

        pdf.text_box name, at: [256, 832], size: 11
        pdf.text_box rank_identity, at: [256, 815], size: 11
        pdf.text_box unit, at: [256, 798], size: 11
        pdf.text_box position, at: [256, 781], size: 11
        pdf.text_box exam_name, at: [256, 764], size: 11
        
        pdf.text_box created_at, at: [18, 60], size: 9
        pdf.text_box exam_session, at: [18, 50], size: 9
        pdf.text_box code, at: [18, 38], size: 11
      end

      template_pdf = CombinePDF.load(template_path)
      overlay_pdf = CombinePDF.load(overlay_pdf_path)

      template_pdf.pages.each do |page|
        page << overlay_pdf.pages[0] if overlay_pdf.pages[0]
      end

      finish_pdf = CombinePDF.new
      finish_pdf << template_pdf
      finish_pdf << template_pdf
      finish_pdf << template_pdf

      finish_pdf.save(output_path)

      # Assign file to Shrine uploader
      File.open(output_path) do |file|
        registration.pdf = file
      end

      if registration.save
        registration.completed!
      else
        registration.error!
      end

      # Clean up the temporary files
      File.delete(output_path) if File.exist?(output_path)
      File.delete(overlay_pdf_path) if File.exist?(overlay_pdf_path)
    rescue => e
      Rails.logger.error "Failed to process document: #{e.message}"
      registration.error!
    end
  end
end
