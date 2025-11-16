class Superadmin::ParticipantsController < ApplicationController
  before_action :check_admin_status
  before_action :superadminonly
  before_action :set_exam, only: [:mass_register]
  def new
    @exams = Exam.where(status: [:active, :draft]).order(:name)
  end

  def mass_register
    identity = params[:identity]
    participant = User.find_by(identity: identity)

    if participant
      if user_registered_for_exam?(participant)
        results = { identity: identity, status: "Gagal: Peserta sudah terdaftar di ujian ini." }
      else
        begin
          register_participant(participant)
          results = { identity: identity, status: "Pendaftaran berhasil!" }
        rescue => e
          results = { identity: identity, status: "Gagal: #{e.message}" }
        end
      end
    else
      results = { identity: identity, status: "Gagal: NRP Peserta tidak ditemukan." }
    end

    render json: results
  end

  private

  def set_exam
    @exam = Exam.find_by(slug: params[:exam_slug])
    if @exam.status == "archieve" || @exam.start_register > Date.today || @exam.exam_date_end < Date.today
      render json: { error: "Ujian tidak tersedia." }, status: :unprocessable_entity
    end
  end

  def user_registered_for_exam?(participant)
    Registration.joins(:exam_session).where(user_id: participant.id, exam_sessions: { exam_id: @exam.id }).exists?
  end

  def find_available_session
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day

    query = @exam.exam_sessions.where("size < max_size AND start_time >= ?", tomorrow_start).order(:start_time)
    session = query.first

    if session.nil?
      session = @exam.exam_sessions.order(:start_time).find { |s| s.size < s.max_size && s.start_time.to_date >= tomorrow_start }
    end

    raise ActiveRecord::RecordNotFound, "Tidak ada sesi tersedia" unless session
    session
  end

  def register_participant(participant)
    Exam.transaction do
      session = find_available_session
      registration = session.registrations.build(user: participant, registration_type: params[:reg_type])
      
      # Calculate and set golongan
      if participant.user_detail.date_of_birth.present? && session.exam_schedule&.exam_date.present?
        age_data = Registration.calculate_age_at_date(participant.user_detail.date_of_birth, session.exam_schedule.exam_date)
        if age_data
          registration.golongan = Registration.age_category(age_data[:years]).to_i
        end
      end
      
      registration.save!
    end
  end

  def superadminonly
    unless current_user.user_detail.is_superadmin_granted
      redirect_to root_path
    end
  end
end
