class Users::PasswordResetsController < ApplicationController
  skip_before_action :authenticate_user!

  RESET_REQUEST_LIMIT = 3
  RESET_TIME_LIMIT = 24.hours

  def new
    @user = User.new
    @forgot_page = true
  end

  def create
    # subject = "menyimpan pengajuan ini."
    wait_message = "Pengajuan kata sandi baru Anda sedang ditinjau. Harap tunggu hingga 3 hari kerja. Jika lebih lama, hubungi operator."
    not_found_message = "atau alamat email tidak sesuai"
    too_much_request = "Terlalu banyak permintaan reset kata sandi. Silakan coba 1 x 24 jam kemudian."

    @forgot_page = true

    identity = password_params[:identity]
    email = password_params[:email]
    password = password_params[:password]
    password_confirmation = password_params[:password_confirmation]
    password_strength = password_params[:password_strength]

    @user = User.new(password_params)

    if identity.blank?
      @user.errors.add(:identity, "tidak boleh kosong.")
      render :new, status: :unprocessable_entity
      return
    end

    user_data = User.find_by(identity: identity)

    unless user_data
      @user.errors.add(:identity, not_found_message)
      render :new, status: :unprocessable_entity
      return
    end

    if user_data.email.present?
      if email.blank? || user_data.email != email
        @user.errors.add(:email, "tidak cocok.")
        render :new, status: :unprocessable_entity
        return
      end
    end

    if password.blank? || password_confirmation.blank?
      @user.errors.add(:password, "atau password konfirmasi tidak boleh kosong.")
      render :new, status: :unprocessable_entity
      return
    end

    if password != password_confirmation
      @user.errors.add(:password, "dan password konfirmasi tidak cocok.")
      render :new, status: :unprocessable_entity
      return
    end

    if user_data.forgotten_count >= RESET_REQUEST_LIMIT && (user_data.forgotten_at.present? && user_data.forgotten_at > RESET_TIME_LIMIT.ago)
      @user.errors.add(:base, too_much_request)
      render :new, status: :unprocessable_entity
      return
    end

    if user_data.update(
      is_forgotten: true,
      forgotten_at: Time.current,
      forgotten_count: user_data.forgotten_count + 1,
      password: password,
      password_confirmation: password_confirmation,
      password_strength: password_strength,
      account_status: :pending
    )
      redirect_to new_user_session_path, notice: wait_message
    else
      @user.errors.add(:password, :too_weak)
      Rails.logger.debug "Failed to update user with ID #{user_data.id}: #{user_data.errors.full_messages}"
      render :new, status: :unprocessable_entity
    end
  end

  private

  def password_params
    params.require(:user).permit(
      :identity,
      :email,
      :password,
      :password_confirmation,
      :password_strength
    )
  end
end
