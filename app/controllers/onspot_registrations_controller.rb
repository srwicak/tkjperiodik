class OnspotRegistrationsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:new, :create, :success, :download]
  before_action :set_exam, only: [:new, :create]
  before_action :set_registration, only: [:success, :download]
  before_action :check_onspot_allowed, only: [:new, :create]

  def new
    # Check if there are available sessions for today
    @available_sessions = @exam.todays_available_sessions
    
    if @available_sessions.empty?
      redirect_to root_path, alert: "Tidak ada sesi ujian yang tersedia untuk hari ini atau sesi sudah penuh."
      return
    end

    # Get ranks based on identity length (will be dynamic via JS)
    @police_ranks = UserDetail.ranks_for_police
    @pns_ranks = UserDetail.ranks_for_pns
    @units = UserDetail.units
  end

  def create
    identity = params[:identity]&.strip
    password = params[:password]
    
    # Validate identity length
    unless [8, 18].include?(identity&.length)
      flash.now[:alert] = "NRP harus 8 digit atau NIP harus 18 digit"
      set_form_variables
      render :new, status: :unprocessable_entity
      return
    end

    # Check if there are available sessions
    available_session = @exam.todays_available_sessions.first
    unless available_session
      flash.now[:alert] = "Semua sesi ujian hari ini sudah penuh"
      set_form_variables
      render :new, status: :unprocessable_entity
      return
    end

    # Parse date of birth from DD-MM-YYYY
    dob_day = params[:dob_day]
    dob_month = params[:dob_month]
    dob_year = params[:dob_year]
    
    unless dob_day.present? && dob_month.present? && dob_year.present?
      flash.now[:alert] = "Tanggal lahir wajib diisi"
      set_form_variables
      render :new, status: :unprocessable_entity
      return
    end

    date_of_birth_str = "#{dob_year}-#{dob_month.rjust(2, '0')}-#{dob_day.rjust(2, '0')}"
    
    begin
      date_of_birth = Date.parse(date_of_birth_str)
    rescue ArgumentError
      flash.now[:alert] = "Format tanggal lahir tidak valid"
      set_form_variables
      render :new, status: :unprocessable_entity
      return
    end

    ActiveRecord::Base.transaction do
      # Check if user already exists
      user = User.find_by(identity: identity)
      
      if user
        # User exists, validate password
        unless user.valid_password?(password)
          flash.now[:alert] = "Kata sandi salah"
          set_form_variables
          render :new, status: :unprocessable_entity
          return
        end

        # Check if already registered for this exam
        if Registration.joins(:exam_session).where(user_id: user.id, exam_sessions: { exam_id: @exam.id }).exists?
          flash.now[:alert] = "Anda sudah terdaftar untuk ujian ini"
          set_form_variables
          render :new, status: :unprocessable_entity
          return
        end

        # Ensure user has user_detail (for existing users who might not have one)
        unless user.user_detail
          user_detail = user.build_user_detail(
            name: params[:name]&.upcase&.strip,
            gender: params[:gender],
            rank: params[:rank],
            position: params[:position]&.upcase&.strip,
            unit: params[:unit],
            date_of_birth: date_of_birth
          )

          unless user_detail.save
            flash.now[:alert] = user_detail.errors.full_messages.join(", ")
            set_form_variables
            render :new, status: :unprocessable_entity
            return
          end
        end
      else
        # Create new user
        user = User.new(
          identity: identity,
          password: password,
          password_confirmation: password,
          is_onboarded: true,
          is_verified: true,
          account_status: :active
        )

        unless user.save
          flash.now[:alert] = user.errors.full_messages.join(", ")
          set_form_variables
          render :new, status: :unprocessable_entity
          return
        end

        # Create user detail
        user_detail = user.build_user_detail(
          name: params[:name]&.upcase&.strip,
          gender: params[:gender],
          rank: params[:rank],
          position: params[:position]&.upcase&.strip,
          unit: params[:unit],
          date_of_birth: date_of_birth
        )

        unless user_detail.save
          flash.now[:alert] = user_detail.errors.full_messages.join(", ")
          set_form_variables
          render :new, status: :unprocessable_entity
          return
        end
      end

      # Calculate golongan based on age at exam date
      exam_date = available_session.exam_schedule.exam_date
      age_data = Registration.calculate_age_at_date(date_of_birth, exam_date)
      golongan = age_data ? Registration.age_category(age_data[:years]).to_i : nil

      # Create registration
      registration = Registration.new(
        user: user,
        exam_session: available_session,
        registration_type: :berkala,
        golongan: golongan,
        tb: params[:tb],
        bb: params[:bb]
      )

      unless registration.save
        flash.now[:alert] = registration.errors.full_messages.join(", ")
        set_form_variables
        render :new, status: :unprocessable_entity
        return
      end

      # Redirect to success page
      redirect_to success_onspot_registration_path(exam_slug: @exam.slug, registration_slug: registration.slug)
    end
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    set_form_variables
    render :new, status: :unprocessable_entity
  rescue => e
    Rails.logger.error "Onspot registration error: #{e.message}"
    Rails.logger.error e.backtrace.join("\n")
    flash.now[:alert] = "Terjadi kesalahan sistem. Silakan coba lagi."
    set_form_variables
    render :new, status: :unprocessable_entity
  end

  def success
    @exam = @registration.exam
    @user = @registration.user
    @user_detail = @user.user_detail
    @exam_schedule = @registration.exam_schedule
  end

  def download
    # Generate PDF synchronously
    GeneratePdfJob.perform_now(@registration.id)
    
    # Reload registration to get updated PDF
    @registration.reload
    
    if @registration.pdf.present?
      # Send file directly instead of redirecting
      send_data @registration.pdf.read,
                filename: "pendaftaran_#{@registration.user.user_detail.name.parameterize}_#{@registration.exam.name.parameterize}.pdf",
                type: 'application/pdf',
                disposition: 'attachment'
    else
      redirect_to success_onspot_registration_path(
        exam_slug: @registration.exam.slug, 
        registration_slug: @registration.slug
      ), alert: "PDF sedang diproses. Silakan coba lagi dalam beberapa saat."
    end
  end

  private

  def set_exam
    @exam = Exam.find_by!(slug: params[:exam_slug])
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Ujian tidak ditemukan"
  end

  def set_registration
    @registration = Registration.find_by!(slug: params[:registration_slug])
    
    # Verify registration is for the correct exam
    unless @registration.exam.slug == params[:exam_slug]
      redirect_to root_path, alert: "Data tidak valid"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to root_path, alert: "Pendaftaran tidak ditemukan"
  end

  def check_onspot_allowed
    unless @exam.allow_onspot_registration?
      redirect_to root_path, alert: "Pendaftaran langsung tidak tersedia untuk ujian ini"
    end
  end

  def set_form_variables
    @police_ranks = UserDetail.ranks_for_police
    @pns_ranks = UserDetail.ranks_for_pns
    @units = UserDetail.units
    @available_sessions = @exam.todays_available_sessions
  end
end
