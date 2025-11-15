class Manage::Score::ScoresController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_score, only: %i[show edit update generate_doc download_doc]
  def index
  end

  def show
    @content = @exam.result_doc.content
  end

  def edits
    @url = edit_manage_score_path(@score.slug)

    # Parse JSON string into a Ruby hash
    @score_data = JSON.parse(@score.score_detail || '{"score":{},"remarks":{}}', symbolize_names: true)

    # Extract the score part from the JSON data
    @score_details = @score_data[:score]
    @remarks = @score_data[:remarks]

    # Convert @score_details from a hash to an array for easy processing
    @categories = @score_sheet[:categories].map do |category|
      {
        name: category[:name],
        content: category[:content].map do |item|
          score_value = @score_details[item[:code].to_sym]
          remarks_value = @remarks[item[:code].to_sym]
          {
            code: item[:code],
            subject: item[:subject],
            amount: item[:amount],
            score: score_value,
            remarks: remarks_value
          }
        end
      }
    end
  end

  def editx
    @url = edit_manage_score_path(@score.slug)

    # Parse JSON string into a Ruby hash
    @score_data = JSON.parse(@score.score_detail || '[]', symbolize_names: true)

    # Setup empty examiner data if not present
    @score_data = {
      0 => { examiner_name: "", score: {}, remarks: {} },
      1 => { examiner_name: "", score: {}, remarks: {} },
      2 => { examiner_name: "", score: {}, remarks: {} }
    }.merge(@score_data)

    # Loop through each examiner
    @categories = @score_sheet[:categories].map do |category|
      {
        name: category[:name],
        content: category[:content].map do |item|
          examiners = (0..2).map do |index|
            score_value = @score_data[index][:score][item[:code].to_sym]
            remarks_value = @score_data[index][:remarks][item[:code].to_sym]
            {
              code: item[:code],
              subject: item[:subject],
              amount: item[:amount],
              score: score_value,
              remarks: remarks_value,
              examiner_name: @score_data[index][:examiner_name],
              examiner_index: index
            }
          end
          { code: item[:code], subject: item[:subject], amount: item[:amount], examiners: examiners }
        end
      }
    end
  end

  # This for 3 examnier with detailed score
  def edity
    @url = edit_manage_score_path(@score.slug)

    # Parse JSON string into a Ruby hash
    @score_data = JSON.parse(@score.score_detail || '{}', symbolize_names: true)

    # Convert array to hash if necessary
    if @score_data.is_a?(Array)
      @score_data = @score_data.each_with_index.map do |data, index|
        [index, data]
      end.to_h
    end

    # Setup empty examiner data if not present
    @score_data = {
      0 => { examiner_name: "", score: {}, remarks: {} },
      1 => { examiner_name: "", score: {}, remarks: {} },
      2 => { examiner_name: "", score: {}, remarks: {} }
    }.merge(@score_data)

    # Loop through each examiner
    @categories = @score_sheet[:categories].map do |category|
      {
        name: category[:name],
        content: category[:content].map do |item|
          examiners = (0..2).map do |index|
            score_value = @score_data[index][:score][item[:code].to_sym]
            remarks_value = @score_data[index][:remarks][item[:code].to_sym]
            {
              code: item[:code],
              subject: item[:subject],
              amount: item[:amount],
              score: score_value,
              remarks: remarks_value,
              examiner_name: @score_data[index][:examiner_name],
              examiner_index: index
            }
          end
          { code: item[:code], subject: item[:subject], amount: item[:amount], examiners: examiners }
        end
      }
    end
  end

  def edit
    @url = edit_manage_score_path(@score.slug)

    # Parse JSON string into a Ruby hash
    @score_data = JSON.parse(@score.score_detail || '{"score":{}}', symbolize_names: true)

    # Extract the score part from the JSON data
    @score_details = @score_data[:score]

    # Convert @score_details from a hash to an array for easy processing
    @categories = @score_sheet[:categories].map do |category|
      {
        name: category[:name],
        content: category[:content].map do |item|
          score_value = @score_details[item[:code].to_sym]
          {
            code: item[:code],
            subject: item[:subject],
            score: score_value,
          }
        end
      }
    end
  end


  def update
    Rails.logger.info "Received parameters: #{params.inspect}"

    attrs = {
      score_detail: score_params[:score_detail],
      score_grade: score_params[:score_grade],
      score_number: score_params[:score_number],
      notes: score_params[:notes],
      exam_present: true
    }

    # set first input metadata if not present, otherwise update last edited metadata
    if @score.first_input_by_id.nil?
      attrs[:first_input_by_id] = current_user.id
      attrs[:first_input_at] = Time.current
      attrs[:last_edited_by_id] = current_user.id
      attrs[:last_edited_at] = Time.current
    else
      attrs[:last_edited_by_id] = current_user.id
      attrs[:last_edited_at] = Time.current
    end

    if @score.update(attrs)
      @registration.update(is_attending: true)
      redirect_to show_manage_score_path(@score.slug), notice: 'Nilai telah sukses dirubah.'
    else
      render :edit
    end
  end

  def search
    score = Score.find_by(code: params[:code])

    if score
      is_scored = score.score_grade.nil?
      registration = score.registration
      exam_session = registration.exam_session
      exam = exam_session.exam
      user = registration.user
      render json: {
        success: true,
        score: {
          slug: score.slug,
          name: user.user_detail.name,
          exam_name: exam.name,
          is_scored: !is_scored,
          #reg_type: score.registration_type,
        }
      }
    else
      render json: { success: false, message: "No score data available" }, status: :not_found
    end
  end

  def generate_doc
    GenerateReportJob.perform_later(@score.id)
    redirect_to show_manage_score_path(@score.slug), notice: 'Dokumen sedang diproses.'
  end

  def download_doc
    if @score.result_doc.exists?
      send_file @score.result_doc.download, filename: @score.result_doc.metadata['filename'], type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', disposition: 'attachment'
    else
      redirect_to root_path, alert: 'Dokumen tidak ditemukan.'
    end
  end



  def data
  end

  private

  def score_params
    params.require(:score).permit(:score_detail, :score_grade, :score_number, :notes)
  end


  def set_score
    @score = Score.find_by!(slug: params[:slug])
    @is_scored = @score.score_grade.nil?
    @registration = @score.registration
    @exam_session = @registration.exam_session
    @exam = @exam_session.exam
    @user = @registration.user

    # Calculate age and check golongan
    @age_at_exam = @registration.age_at_exam
    @golongan = @registration.golongan
    
    # Determine if should use simplified form (golongan 4 or age >= 51)
    @use_simplified_form = (@golongan == 4) || (@age_at_exam && @age_at_exam >= 51)

    # New score sheet for Ujian Kesamaptaan Jasmani
    if @use_simplified_form
      # Simplified form: Only Ujian Kesamaptaan A
      @score_sheet = {
        "exam_type": "kesamaptaan_simplified",
        "categories": [
          {
            "code": "kesamaptaan_a",
            "name": "Ujian Kesamaptaan A",
            "content": [
              { "code": "lari_12_menit", "subject": "LARI 12 MENIT" }
            ]
          }
        ]
      }
    else
      # Full form: Ujian Kesamaptaan A + B
      @score_sheet = {
        "exam_type": "kesamaptaan_full",
        "categories": [
          {
            "code": "kesamaptaan_a",
            "name": "Ujian Kesamaptaan A",
            "content": [
              { "code": "lari_12_menit", "subject": "LARI 12 MENIT" }
            ]
          },
          {
            "code": "kesamaptaan_b",
            "name": "Ujian Kesamaptaan B",
            "content": [
              { "code": "pull_ups", "subject": "PULL-UPS" },
              { "code": "sit_ups", "subject": "SIT-UPS" },
              { "code": "push_ups", "subject": "PUSH-UPS" },
              { "code": "shuttle_run", "subject": "SHUTTLE RUN" }
            ]
          }
        ]
      }
    end

    # @score_sheet = {
    #   "exam_type": "beladiri_polri",
    #   "categories": [
    #     {
    #       "code": "basic",
    #       "name": "teknik dasar beladiri polri",
    #       "content": [
    #         { "code": "basic_1", "subject": "Jatuh ke kiri/kanan", "amount": 2 },
    #         { "code": "basic_2", "subject": "Jatuh ke depan/belakang", "amount": 2 },
    #         { "code": "basic_3", "subject": "Roll depan jatuh kiri/kanan", "amount": 2 },
    #         { "code": "basic_4", "subject": "Pukulan dan tangkisan", "amount": 13 },
    #         { "code": "basic_5", "subject": "Tendangan", "amount": 4 },
    #         { "code": "basic_6", "subject": "Dasar membawa tahanan", "amount": 4 }
    #       ]
    #     },
    #     {
    #       "code": "no_tools",
    #       "name": "teknik beladiri tanpa alat",
    #       "content": [
    #         { "code": "no_tools_1", "subject": "Melepas pengangan tangan", "amount": 2 },
    #         { "code": "no_tools_2", "subject": "Melepas pegangan baju", "amount": 2 },
    #         { "code": "no_tools_3", "subject": "Melepas cekikan", "amount": 2 },
    #         { "code": "no_tools_4", "subject": "Melepas sekapan", "amount": 2 },
    #         { "code": "no_tools_5", "subject": "Menghindari pukulan", "amount": 3 },
    #         { "code": "no_tools_6", "subject": "Menghindari tendangan", "amount": 1 },
    #         { "code": "no_tools_7", "subject": "Menghindari serangan tongkat", "amount": 2 },
    #         { "code": "no_tools_8", "subject": "Menghindari serangan pisau", "amount": 2 },
    #         { "code": "no_tools_9", "subject": "Menghindari serangan pistol", "amount": 2 },
    #         { "code": "no_tools_10", "subject": "Menghindari serangan clurit", "amount": 2 },
    #       ]
    #     },
    #     {
    #       "code": "tools",
    #       "name": "teknik beladiri dengan alat membawa alat",
    #       "content": [
    #         { "code": "tools_1", "subject": "Tongkat sebagai alat menghadapi tusukan pisau dari depan", "amount": 2 },
    #         { "code": "tools_2", "subject": "Tongkat sebagai alat menghadapi bacokan clurit arah kepala", "amount": 2 },
    #         { "code": "tools_3", "subject": "Borgol sebagai alat menghadapi pukulan tongkat ke arah kepala", "amount": 1 },
    #         { "code": "tools_4", "subject": "Kopelrim sebagai alat menghadapi tikaman pisau", "amount": 1 }
    #       ]
    #     }
    #   ]
    # }
  end
end
