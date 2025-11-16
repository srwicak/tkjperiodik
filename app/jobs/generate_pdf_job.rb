require 'rqrcode'

class GeneratePdfJob < ApplicationJob
  queue_as :default

  def perform(registration_id)
    registration = Registration.find_by(id: registration_id)
    return unless registration

    return if registration.completed?

    registration.processing!

    user_detail = registration.user.user_detail
    exam = registration.exam_session.exam
    exam_schedule = registration.exam_schedule
    
    # Calculate age at exam date
    age_at_exam = nil
    if user_detail.date_of_birth.present? && exam_schedule&.exam_date.present?
      exam_date = exam_schedule.exam_date
      dob = user_detail.date_of_birth
      age_at_exam = exam_date.year - dob.year
      age_at_exam -= 1 if exam_date.month < dob.month || (exam_date.month == dob.month && exam_date.day < dob.day)
    end
    
    # Determine which templates to use based on age
    # < 51 years: use both ukj-a and ukj-b
    # >= 51 years: use only ukj-a
    use_both_forms = age_at_exam.present? && age_at_exam < 51
    
    name = user_detail.name.upcase
    # Combine rank and NRP (check how it's written in the file)
    rank_nrp = "#{user_detail.rank.upcase}/#{registration.user.identity}"
    unit = user_detail.unit.upcase
    
    # Format exam date in Indonesian (17 AGUSTUS 1945)
    exam_date_formatted = ""
    if exam_schedule&.exam_date.present?
      exam_date_formatted = I18n.l(exam_schedule.exam_date, format: :default).upcase
    end
    
    # Format date of birth in Indonesian (17 AGUSTUS 1945)
    date_of_birth_formatted = ""
    if user_detail.date_of_birth.present?
      date_of_birth_formatted = I18n.l(user_detail.date_of_birth, format: :default).upcase
    end
    
    # Golongan saat ujian
    golongan = ""
    if registration.golongan.present?
      case registration.golongan
      when 1
        golongan = "1 (USIA 18-30 TAHUN)"
      when 2
        golongan = "2 (USIA 31-40 TAHUN)"
      when 3
        golongan = "3 (USIA 41-50 TAHUN)"
      when 4
        golongan = "4 (USIA 51 TAHUN KE ATAS)"
      else
        golongan = registration.golongan.to_s
      end
    end
    
    # Registration code for bottom of each page
    code = "#{registration.score.code[0, 3]}-#{registration.score.code[-4, 4]}"
    
    # Generate QR code for quick access - use Rails URL helper for dynamic domain
    qr_code_url = Rails.application.routes.url_helpers.qr_access_manage_score_url(code: code, host: ENV.fetch('APP_HOST', 'localhost:3000'))
    qrcode = RQRCode::QRCode.new(qr_code_url)
    
    # 2025 Update - Exam name
    exam_name = exam.name.upcase

    # Data Penandatangan Form A
    form_a_police_position = exam.form_a_police_position.present? ? exam.form_a_police_position.upcase : nil
    form_a_exam_position = exam.form_a_event_position.present? ? exam.form_a_event_position.upcase : ""
    form_a_name = exam.form_a_name.present? ? exam.form_a_name.upcase : ""
    form_a_rank_nrp = ""
    if exam.form_a_rank.present? && exam.form_a_nrp.present?
      form_a_rank_nrp = "#{exam.form_a_rank.upcase} NRP #{exam.form_a_nrp}"
    elsif exam.form_a_rank.present?
      form_a_rank_nrp = exam.form_a_rank.upcase
    end

    # Data Penandatangan Form B
    form_b_police_position = exam.form_b_police_position.present? ? exam.form_b_police_position.upcase : nil
    form_b_exam_position = exam.form_b_event_position.present? ? exam.form_b_event_position.upcase : ""
    form_b_name = exam.form_b_name.present? ? exam.form_b_name.upcase : ""
    form_b_rank_nrp = ""
    if exam.form_b_rank.present? && exam.form_b_nrp.present?
      form_b_rank_nrp = "#{exam.form_b_rank.upcase} NRP #{exam.form_b_nrp}"
    elsif exam.form_b_rank.present?
      form_b_rank_nrp = exam.form_b_rank.upcase
    end

    # Print date using exam date (Jakarta, 10 Oktober 2025)
    print_date = ""
    if exam_schedule&.exam_date.present?
      print_date = "Jakarta, #{I18n.l(exam_schedule.exam_date, format: :default)}"
    end

    # Template paths
    template_a_path = Rails.root.join("private", "assets", "templates", "tkj-a.pdf")
    template_b_path = Rails.root.join("private", "assets", "templates", "tkj-b.pdf")
    output_path = Rails.root.join("tmp", "pendaftaran_#{SecureRandom.hex}.pdf")

    unless File.exist?(template_a_path)
      Rails.logger.error "Template file not found: #{template_a_path}"
      registration.error!
      return
    end
    
    if use_both_forms && !File.exist?(template_b_path)
      Rails.logger.error "Template file not found: #{template_b_path}"
      registration.error!
      return
    end

    begin
      times_font_path = Rails.root.join("private", "assets", "fonts", "times.ttf")
      times_bold_font_path = Rails.root.join("private", "assets", "fonts", "times-b.ttf")
      overlay_form_a_path = Rails.root.join("tmp", "overlay_form_a_#{SecureRandom.hex}.pdf")
      overlay_form_b_path = Rails.root.join("tmp", "overlay_form_b_#{SecureRandom.hex}.pdf")

      # Generate overlay for Form A
      Prawn::Document.generate(overlay_form_a_path, margin: 0, page_size: "LEGAL") do |pdf|
        pdf.font_families.update("Times" => {
          normal: times_font_path,
          bold: times_bold_font_path,
          italic: times_font_path,
          bold_italic: times_bold_font_path,
        })
        pdf.font "Times"
        
        # Exam name - centered, bold, underlined, size 14
        pdf.formatted_text_box(
          [{ text: exam_name, styles: [:bold, :underline] }],
          at: [0, 844],
          width: 612,
          height: 50,
          size: 14,
          align: :center
        )
        
        # Participant data - all uppercase, size 12
        y_pos = 795
        x_pos = 184
        pdf.text_box name, at: [x_pos, y_pos], size: 12
        y_pos -= 32
        pdf.text_box rank_nrp, at: [x_pos, y_pos], size: 12
        y_pos -= 32
        pdf.text_box unit, at: [x_pos, y_pos], size: 12
        y_pos -= 32
        pdf.text_box date_of_birth_formatted, at: [x_pos, y_pos], size: 12
        y_pos -= 32
        pdf.text_box golongan, at: [x_pos, y_pos], size: 12
        
        # Print date (Jakarta, tanggal ujian) - lowered by 32px
        pdf.text_box print_date, at: [350, 438], size: 12, width: 220, align: :center, style: :bold
        
        # Signer box for Form A (right side of page) - lowered by 32px
        signer_y = 408
        signer_x = 350
        
        # Jabatan Polisi (kalau ada)
        if form_a_police_position.present?
          pdf.text_box form_a_police_position, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
          signer_y -= 20
          pdf.text_box "SEBAGAI", at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
          signer_y -= 20
        end
        
        # Jabatan Ujian
        if form_a_exam_position.present?
          pdf.text_box form_a_exam_position, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
          signer_y -= 20
        end
        
        # Space for signature
        signer_y -= 30
        
        # Nama
        if form_a_name.present?
          pdf.text_box form_a_name, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
          signer_y -= 20
        else
          # If no name, lower the line more
          signer_y -= 30
        end
        
        # Garis
        pdf.stroke do
          pdf.line [signer_x, signer_y], [signer_x + 220, signer_y]
        end
        signer_y -= 5
        
        # Rank NRP
        if form_a_rank_nrp.present?
          pdf.text_box form_a_rank_nrp, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
        end
        
        # QR Code and Code at bottom
        # Generate QR code as PNG in memory
        qr_png = qrcode.as_png(
          bit_depth: 1,
          border_modules: 0,
          color_mode: ChunkyPNG::COLOR_GRAYSCALE,
          color: 'black',
          file: nil,
          fill: 'white',
          module_px_size: 3,
          resize_exactly_to: false,
          resize_gte_to: 60
        )
        
        # Save QR code to temp file
        qr_temp_path = Rails.root.join("tmp", "qr_#{SecureRandom.hex}.png")
        IO.binwrite(qr_temp_path, qr_png.to_s)
        
        # Add QR code image above the text (same X position as code text: 24)
        pdf.image qr_temp_path, at: [24, 96], width: 60, height: 60
        
        # Delete temp QR file
        File.delete(qr_temp_path) if File.exist?(qr_temp_path)
        
        # Code at bottom (below QR code with 8px spacing)
        pdf.text_box "KODE REGISTRASI: #{code}", at: [24, 28], size: 10
      end

      # Generate overlay for Form B (if needed)
      if use_both_forms
        Prawn::Document.generate(overlay_form_b_path, margin: 0, page_size: "LEGAL") do |pdf|
          pdf.font_families.update("Times" => {
            normal: times_font_path,
            bold: times_bold_font_path,
            italic: times_font_path,
            bold_italic: times_bold_font_path,
          })
          pdf.font "Times"
          
          # Exam name - centered, bold, underlined, size 14
          pdf.formatted_text_box(
            [{ text: exam_name, styles: [:bold, :underline] }],
            at: [0, 844],
            width: 612,
            height: 50,
            size: 14,
            align: :center
          )
          
          # Participant data - all uppercase, size 12
          y_pos = 795
          x_pos = 184
          pdf.text_box name, at: [x_pos, y_pos], size: 12
          y_pos -= 32
          pdf.text_box rank_nrp, at: [x_pos, y_pos], size: 12
          y_pos -= 32
          pdf.text_box unit, at: [x_pos, y_pos], size: 12
          y_pos -= 32
          pdf.text_box date_of_birth_formatted, at: [x_pos, y_pos], size: 12
          y_pos -= 32
          pdf.text_box golongan, at: [x_pos, y_pos], size: 12
          
          # Print date (Jakarta, tanggal ujian) - lowered by 32px
          pdf.text_box print_date, at: [350, 238], size: 12, width: 220, align: :center, style: :bold
          
          # Signer box for Form B (right side of page) - lowered by 32px
          signer_y = 208
          signer_x = 350
          
          # Jabatan Polisi (kalau ada)
          if form_b_police_position.present?
            pdf.text_box form_b_police_position, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
            signer_y -= 20
            pdf.text_box "SEBAGAI", at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
            signer_y -= 20
          end
          
          # Jabatan Ujian
          if form_b_exam_position.present?
            pdf.text_box form_b_exam_position, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
            signer_y -= 20
          end
          
          # Space for signature
          signer_y -= 30
          
          # Nama
          if form_b_name.present?
            pdf.text_box form_b_name, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
            signer_y -= 20
          else
            # If no name, lower the line more
            signer_y -= 30
          end
          
          # Garis
          pdf.stroke do
            pdf.line [signer_x, signer_y], [signer_x + 220, signer_y]
          end
          signer_y -= 5
          
          # Rank NRP
          if form_b_rank_nrp.present?
            pdf.text_box form_b_rank_nrp, at: [signer_x, signer_y], size: 12, width: 220, align: :center, style: :bold
          end          # QR Code and Code at bottom
          # Generate QR code as PNG in memory
          qr_png = qrcode.as_png(
            bit_depth: 1,
            border_modules: 0,
            color_mode: ChunkyPNG::COLOR_GRAYSCALE,
            color: 'black',
            file: nil,
            fill: 'white',
            module_px_size: 3,
            resize_exactly_to: false,
            resize_gte_to: 60
          )
          
          # Save QR code to temp file
          qr_temp_path = Rails.root.join("tmp", "qr_#{SecureRandom.hex}.png")
          IO.binwrite(qr_temp_path, qr_png.to_s)
          
          # Add QR code image above the text (same X position as code text: 24)
          pdf.image qr_temp_path, at: [24, 96], width: 60, height: 60
          
          # Delete temp QR file
          File.delete(qr_temp_path) if File.exist?(qr_temp_path)
          
          # Code at bottom (below QR code with 8px spacing)
          pdf.text_box "KODE REGISTRASI: #{code}", at: [24, 28], size: 10
        end
      end

      # Load overlays and templates
      overlay_form_a = CombinePDF.load(overlay_form_a_path)
      
      # Combine Form A
      template_a_pdf = CombinePDF.load(template_a_path)
      template_a_pdf.pages[0] << overlay_form_a.pages[0] if overlay_form_a.pages[0]

      # Create final PDF
      finish_pdf = CombinePDF.new
      finish_pdf << template_a_pdf

      # Add Form B if age < 51
      if use_both_forms
        overlay_form_b = CombinePDF.load(overlay_form_b_path)
        template_b_pdf = CombinePDF.load(template_b_path)
        template_b_pdf.pages[0] << overlay_form_b.pages[0] if overlay_form_b.pages[0]
        finish_pdf << template_b_pdf
      end

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
      File.delete(overlay_form_a_path) if File.exist?(overlay_form_a_path)
      File.delete(overlay_form_b_path) if File.exist?(overlay_form_b_path) && use_both_forms
    rescue => e
      Rails.logger.error "Failed to process document: #{e.message}"
      Rails.logger.error e.backtrace.join("\n")
      registration.error!
    end
  end
end
