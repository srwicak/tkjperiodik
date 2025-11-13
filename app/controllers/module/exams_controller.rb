class Module::ExamsController < ApplicationController
  before_action :check_admin_status
  before_action :police_only, except: :index
  before_action :set_exam, only: %i[show new create]
  def index
    @police = current_user.is_police?
    today = Date.today
    @exams = Exam.where("exam_date_end > ?", today).where(status: :active).order(:start_register)
  end

  def show
    session_calculation
    @is_registered = user_registered_for_exam?
    
    # 2025 Update - Check using exam schedules
    @available_schedules = @exam.exam_schedules
      .where("exam_date >= ?", Date.tomorrow)
      .order(:exam_date)
    
    # Check if user's unit has any available schedule
    if current_user.is_police?
      user_unit = current_user.user_detail.unit
      @user_available_schedules = @available_schedules.select { |schedule| schedule.available_for_unit?(user_unit) }
    else
      @user_available_schedules = []
    end
    
    if @exam.registered_count >= (@exam.batch * @exam.size * @exam_days)
      @full_capacity = true
    end
  end

  def new
    if Registration.joins(:exam_session).where(user_id: current_user.id, exam_sessions: { exam_id: @exam.id }).exists?
      redirect_to index_module_history_path, notice: "Anda sudah terdaftar"
      return
    end
    if @exam.registered_count >= (@exam.batch * @exam.size * @exam_days)
      redirect_to index_module_history_path, alert: "Kuota sudah penuh!"
      return
    end
    
    @user = current_user
    session_calculation
    
    # 2025 Update - Get available schedules for user's unit
    user_unit = @user.user_detail.unit
    @available_schedules = @exam.exam_schedules
      .where("exam_date >= ?", Date.tomorrow)
      .select { |schedule| schedule.available_for_unit?(user_unit) }
      .sort_by(&:exam_date)
    
    if @available_schedules.empty?
      redirect_to show_module_exam_path(@exam.slug), alert: "Belum ada jadwal ujian yang tersedia untuk satuan Anda."
      return
    end
  end

  # 2024 version
  # def create
  #   @user = current_user

  #   unless params[:reg_type].present?
  #     flash[:alert] = "Anda harus memilih salah satu jenis keikutsertaan ujian."
  #     redirect_to new_module_exam_path(@exam.slug) and return
  #   end

  #   Exam.transaction do
  #     session = find_available_session(@exam)
  #     registration = session.registrations.create!(user: @user, registration_type: params[:reg_type])
  #     # GeneratePdfJob.perform_later(registration.id)
  #     redirect_to show_module_history_path(registration.slug), notice: "Pendaftaran Berhasil! Segera cetak berkas pendaftaran!"
  #   end

  # rescue ActiveRecord::RecordNotFound => e
  #   logger.error "No available sessions found for exam #{@exam.id}"
  #   redirect_to index_module_exam_path, alert: "Semua sesi telah penuh atau tidak ada sesi yang tersedia."
  # rescue ActiveRecord::RecordInvalid => e
  #   logger.error "Registration failed: #{e.message}"
  #   redirect_to index_module_exam_path, alert: e.message
  # end

  # 2025 Update
  # This version is more robust and handles various edge cases better.
  # Now supports exam schedules
  def create
    @user = current_user

    unless params[:reg_type].present?
      flash[:alert] = "Anda harus memilih salah satu jenis keikutsertaan ujian."
      redirect_to new_module_exam_path(@exam.slug) and return
    end

    unless params[:exam_schedule_id].present?
      flash[:alert] = "Anda harus memilih jadwal ujian."
      redirect_to new_module_exam_path(@exam.slug) and return
    end

    Exam.transaction do
      # Find the selected schedule
      schedule = @exam.exam_schedules.find_by(id: params[:exam_schedule_id])
      
      unless schedule
        flash[:alert] = "Jadwal ujian tidak ditemukan."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      # Check if schedule is available for user's unit
      user_unit = @user.user_detail.unit
      unless schedule.available_for_unit?(user_unit)
        flash[:alert] = "Jadwal ujian tidak tersedia untuk satuan Anda."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      # Check if schedule is full
      if schedule.full?
        flash[:alert] = "Jadwal ujian sudah penuh."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      # Get or create exam session for this schedule
      session = schedule.exam_sessions.first

      registration = Registration.find_or_initialize_by(user: @user, exam_session: session)

      if registration.persisted?
        redirect_to show_module_history_path(registration.slug), notice: "Anda sudah terdaftar sebelumnya."
        return
      end

      registration.registration_type = params[:reg_type]
      registration.save!

      redirect_to show_module_history_path(registration.slug), notice: "Pendaftaran Berhasil! Segera cetak berkas pendaftaran!"
    end

  rescue ActiveRecord::RecordNotUnique
    redirect_to index_module_history_path, alert: "Anda sudah terdaftar sebelumnya."
  rescue ActiveRecord::RecordNotFound => e
    logger.error "No available sessions found for exam #{@exam.id}"
    redirect_to index_module_exam_path, alert: "Semua sesi telah penuh atau tidak ada sesi yang tersedia."
  rescue ActiveRecord::RecordInvalid => e
    logger.error "Registration failed: #{e.message}"
    redirect_to index_module_exam_path, alert: e.message
  end


  private

  def police_only
    unless current_user.is_police?
      redirect_to index_module_exam_path and return
    end
  end

  def session_calculation
    exam_start = @exam.exam_start
    exam_duration = @exam.exam_duration.minutes
    break_time = @exam.break_time.minutes
    batch = [@exam.batch, 10].min

    @sessions = []
    batch.times do |i|
      session_start = exam_start
      session_end = session_start + exam_duration
      @sessions << { start: session_start, end: session_end }
      exam_start = session_end + break_time
    end
  end

  def find_available_session(exam)
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day

    query = exam.exam_sessions.where("size < max_size AND start_time >= ?", tomorrow_start).order(:start_time)
    session = query.first

    if session.nil?
      session = exam.exam_sessions.order(:start_time).find { |s| s.size < s.max_size && s.start_time.to_date >= today_local }
    end

    raise ActiveRecord::RecordNotFound, "Tidak ada sesi tersedia" unless session
    session
  end

  def user_registered_for_exam?
    Registration.joins(:exam_session).where(user_id: current_user.id, exam_sessions: { exam_id: @exam.id }).exists?
  end

  def set_exam
    @exam = Exam.find_by!(slug: params[:slug])
    if @exam.status != "active" || @exam.start_register > Date.today || @exam.exam_date_end < Date.today
      redirect_to index_module_exam_path
    end
    #only warking days
    start_date = @exam.exam_date_start
    end_date = @exam.exam_date_end
    @exam_days = (start_date..end_date).count { |date| (1..5).include?(date.wday) }
  end
end
