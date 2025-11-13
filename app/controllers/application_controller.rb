class ApplicationController < ActionController::Base
  require_dependency 'admin_status'
  rescue_from ActiveRecord::RecordNotFound, with: :record_not_found

  before_action :configure_permitted_parameters, if: :devise_controller?
  # before_action :authenticate_user!

  include AdminStatus

  def record_not_found
    redirect_back(fallback_location: root_path, alert: "Laman yang Anda cari tidak ditemukan.")
  end
  # def record_not_found
  #   render file: "#{Rails.root}/public/404.html", status: :not_found
  # end


  protected
  def configure_permitted_parameters
    added_attrs = [:email, :identity, :password, :password_confirmation, :remember_me]
    devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
    devise_parameter_sanitizer.permit :sign_in, keys: [:identity, :password]
    devise_parameter_sanitizer.permit :account_update, keys: added_attrs
  end
end
