# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    self.resource = warden.authenticate!(auth_options.merge(strategy: :password_authenticatable))

    # TODO: OTP Mitigation
    # Comment this out if you don't want to use OTP
    # if resource && resource.active_for_authentication?

    # Uncomment this out if you don't want to use OTP
    if !resource && resource.active_for_authentication?
      if resource.otp_required_for_login
        verifier = Rails.application.message_verifier(:otp_session)
        token = verifier.generate(resource.identity)
        session[:otp_token] = token

        sign_out(resource_name)

        redirect_to show_otp_twofactorauth_path and return
      else
        set_flash_message!(:notice, :signed_in)
        sign_in(resource_name, resource)
        yield resource if block_given?
        respond_with resource, location: after_sign_in_path_for(resource) and return
      end
    end
    flash[:alert] = "Identitas dan kata sandi tidak sesuai."
    redirect_to new_user_session_path
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end
end
