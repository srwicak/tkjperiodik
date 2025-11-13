class TwofactorauthController < ApplicationController
  skip_before_action :authenticate_user!, only: %i[show_otp verify_otp]
  before_action :ensure_valid_otp_token, only: %i[show_otp verify_otp]
  before_action :only_operator_superadmin, only: %i[setup setup_verify]

  def show_otp
    # Render the OTP setup page
    @otp_page = true
  end

  def verify_otp
    verifier = Rails.application.message_verifier(:otp_session)
    user_identity = verifier.verify(session[:otp_token])
    user = User.find_for_database_authentication(identity: user_identity)

    if user.validate_and_consume_otp!(params[:otp_attempt])
      sign_in(:user, user)
      redirect_to root_path, notice: t("twofactorauth.success_otp_login")
    else
      flash[:alert] = t("twofactorauth.invalid_otp_code")
      redirect_to new_user_session_path
    end
  end

  def setup
    current_user.otp_secret = User.generate_otp_secret
    issuer = "PangkatPlus-POLRI"
    label = "#{issuer}:#{current_user.identity}"

    @provisioning_uri = current_user.otp_provisioning_uri(label, issuer: issuer)
    current_user.save!
  end

  def setup_verify
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.otp_required_for_login = true
      current_user.save!
      redirect_to index_dashboard_path, notice: t("twofactorauth.success_otp_setup")
    else
      redirect_to setup_twofactorauth_path, alert: t("twofactorauth.wrong_otp_setup")
    end
  end

  def disable_otp
    # current_user.otp_required_for_login = false
    # current_user.save!
    # redirect_to root_path

    # Preferred approach, something like this:
    if current_user.validate_and_consume_otp!(params[:otp_attempt])
      current_user.otp_required_for_login = false
      current_user.save!
      redirect_to root_path, notice: "Two-factor authentication disabled successfully."
    else
      flash[:alert] = "Invalid OTP code."
      redirect_back(fallback_location: root_path)
    end
  end

  private
  def ensure_valid_otp_token
    verifier = Rails.application.message_verifier(:otp_session)
    unless session[:otp_token] && verifier.valid_message?(session[:otp_token])
      redirect_to new_user_session_path, alert: t("twofactorauth.invalid_otp_code")
    end
  end

  def only_operator_superadmin
    redirect_to root_path unless (current_user.user_detail.is_operator_granted? || current_user.user_detail.is_superadmin_granted?) && !current_user.otp_required_for_login && current_user.active?
  end
end
