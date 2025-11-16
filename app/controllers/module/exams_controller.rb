class Module::ExamsController < ApplicationController
  before_action :check_admin_status
  before_action :set_exam, only: %i[show new create]
  def index
    today = Date.today
    @exams = Exam.where("exam_date_end > ?", today).where(status: :active).order(:start_register)
  end

  def show
    @is_registered = user_registered_for_exam?
    
    # 2025 Update - Check using exam schedules
    # Allow all users to see all schedules regardless of unit
    @available_schedules = @exam.exam_schedules
      .includes(exam_sessions: :registrations)
      .where("exam_date >= ?", Date.today)
      .order(:exam_date)
    
    # Check if all schedules are full
    @full_capacity = @available_schedules.present? && @available_schedules.all?(&:full?)
  end

  def new
    if Registration.joins(:exam_session).where(user_id: current_user.id, exam_sessions: { exam_id: @exam.id }).exists?
      redirect_to index_module_history_path, notice: "Anda sudah terdaftar"
      return
    end
    
    @user = current_user
    
    # 2025 Update - Get all available schedules regardless of unit
    # Eager load exam_sessions and their registrations for performance
    @available_schedules = @exam.exam_schedules
      .includes(exam_sessions: :registrations)
      .where("exam_date >= ?", Date.today)
      .order(:exam_date)
    
    if @available_schedules.empty?
      redirect_to show_module_exam_path(@exam.slug), alert: "Belum ada jadwal ujian yang tersedia."
      return
    end
    
    # Check if all schedules are full
    if @available_schedules.all?(&:full?)
      redirect_to show_module_exam_path(@exam.slug), alert: "Semua jadwal ujian sudah penuh!"
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

    # Check if date of birth is present
    unless @user.user_detail.date_of_birth.present?
      flash[:alert] = "Tanggal lahir Anda belum diisi. Silakan lengkapi profil Anda terlebih dahulu."
      redirect_to edit_module_profile_path and return
    end

    unless params[:reg_type].present?
      flash[:alert] = "Anda harus memilih salah satu jenis keikutsertaan ujian."
      redirect_to new_module_exam_path(@exam.slug) and return
    end

    unless params[:selected_date].present?
      flash[:alert] = "Anda harus memilih tanggal ujian."
      redirect_to new_module_exam_path(@exam.slug) and return
    end

    Exam.transaction do
      # Parse selected_date format: "schedule_id|exam_date"
      schedule_id, exam_date_str = params[:selected_date].split('|')
      exam_date = Date.parse(exam_date_str) rescue nil
      
      unless schedule_id && exam_date
        flash[:alert] = "Format tanggal ujian tidak valid."
        redirect_to new_module_exam_path(@exam.slug) and return
      end
      
      # Find the selected schedule
      schedule = @exam.exam_schedules.find_by(id: schedule_id)
      
      unless schedule
        flash[:alert] = "Jadwal ujian tidak ditemukan."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      # Check if schedule is full
      if schedule.full?
        flash[:alert] = "Jadwal ujian sudah penuh."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      # Find exam session for the specific date
      # Use BETWEEN to handle timezone properly
      start_of_day = exam_date.in_time_zone.beginning_of_day
      end_of_day = exam_date.in_time_zone.end_of_day
      session = schedule.exam_sessions.find_by("start_time BETWEEN ? AND ?", start_of_day, end_of_day)
      
      unless session
        flash[:alert] = "Sesi ujian untuk tanggal tersebut tidak ditemukan."
        redirect_to new_module_exam_path(@exam.slug) and return
      end

      registration = Registration.find_or_initialize_by(user: @user, exam_session: session)

      if registration.persisted?
        redirect_to show_module_history_path(registration.slug), notice: "Anda sudah terdaftar sebelumnya."
        return
      end

      # Set default registration type to berkala
      registration.registration_type = params[:reg_type] || 'berkala'
      
      # Set golongan based on age category
      if params[:golongan].present?
        registration.golongan = params[:golongan]
      else
        # Calculate golongan as backup if not provided from form
        if @user.user_detail.date_of_birth.present? && exam_date.present?
          age_data = Registration.calculate_age_at_date(@user.user_detail.date_of_birth, exam_date)
          if age_data
            registration.golongan = Registration.age_category(age_data[:years]).to_i
            Rails.logger.info "Golongan calculated server-side: #{registration.golongan} for user #{@user.id}"
          end
        end
      end
      
      # Set TB and BB from params
      registration.tb = params[:tb] if params[:tb].present?
      registration.bb = params[:bb] if params[:bb].present?
      
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
    # Check if exam is active and registration period is valid
    if @exam.status != "active" || @exam.start_register > Date.today
      redirect_to index_module_exam_path
      return
    end
    
    # 2025 Update: Check if exam has any schedules
    # If exam has schedules, use them. Otherwise fall back to exam_date_end
    if @exam.has_schedules?
      latest_schedule = @exam.exam_schedules.maximum(:exam_date_end) || @exam.exam_schedules.maximum(:exam_date)
      if latest_schedule && latest_schedule < Date.today
        redirect_to index_module_exam_path
      end
    elsif @exam.exam_date_end.present? && @exam.exam_date_end < Date.today
      redirect_to index_module_exam_path
    end
  end
end
