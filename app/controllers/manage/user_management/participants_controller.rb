class Manage::UserManagement::ParticipantsController < ApplicationController
  before_action :check_admin_status
  before_action :set_exam, only: [:mass_register]
  
  def new
    @exams = Exam.where(status: [:active, :draft]).order(:name)
  end

  def mass_register
    identity = params[:identity]
    participant = User.find_by(identity: identity)

    # Validate identity format
    unless identity.length == 8 || identity.length == 18
      render json: { identity: identity, status: "Gagal: Identitas harus 8 digit (NRP) atau 18 digit (NIP)." }
      return
    end

    if participant
      if user_registered_for_exam?(participant)
        results = { identity: identity, status: "Gagal: Peserta sudah terdaftar di ujian ini." }
      else
        begin
          register_participant(participant)
          identity_type = identity.length == 8 ? "NRP" : "NIP"
          results = { identity: identity, status: "Pendaftaran berhasil! (#{identity_type})" }
        rescue => e
          results = { identity: identity, status: "Gagal: #{e.message}" }
        end
      end
    else
      identity_type = identity.length == 8 ? "NRP" : "NIP"
      results = { identity: identity, status: "Gagal: #{identity_type} tidak ditemukan." }
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
    today_start = Time.zone.now.beginning_of_day

    query = @exam.exam_sessions.where("size < max_size AND start_time >= ?", today_start).order(:start_time)
    session = query.first

    if session.nil?
      session = @exam.exam_sessions.order(:start_time).find { |s| s.size < s.max_size && s.start_time.to_date >= today_start }
    end

    raise ActiveRecord::RecordNotFound, "Tidak ada sesi tersedia" unless session
    session
  end

  def register_participant(participant)
    Exam.transaction do
      session = find_available_session
      registration = session.registrations.build(
        user: participant, 
        registration_type: params[:reg_type],
        tb: params[:tb].presence,
        bb: params[:bb].presence
      )
      
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
end
