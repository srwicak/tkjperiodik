# frozen_string_literal: true

class Users::PasswordsController < Devise::PasswordsController
  # GET /resource/password/new
  # def new
  #   super
  # end

  # POST /resource/password
  def create
    # self.resource = resource_class.send_reset_password_instructions(resource_params)
    # yield resource if block_given?

    # if successfully_sent?(resource)
    #   respond_with({}, location: after_sending_reset_password_instructions_path_for(resource_name))
    # else
    #   respond_with(resource)
    # end
    self.resource = resource_class.send_reset_password_instructions(resource_params)
    if params[:user][:identity].blank?
      resource.errors.add(:identity, "NRP/NIP harus diisi.")
      redirect_to new_user_password_path
      return
    end
  end

  # GET /resource/password/edit?reset_password_token=abcdef
  # def edit
  #   super
  # end

  # PUT /resource/password
  def update
    self.resource = resource_class.reset_password_by_token(resource_params)
    yield resource if block_given?

    if resource.errors.empty?
      resource.unlock_access!
      resource.is_forgotten = false
      resource.save
      set_flash_message!(:notice, :updated_not_active)
      respond_with resource, location: after_resetting_password_path_for(resource)
    else
      respond_with resource
    end
  end

  protected

  def password_params
    params.require(:user).permit(:password, :password_confirmation)
  end

  def add_error_and_render_new(attribute, message)
    resource.errors.add(attribute, message)
    render :new
  end

  # def after_resetting_password_path_for(resource)
  #   super(resource)
  # end

  # The path used after sending reset password instructions
  # def after_sending_reset_password_instructions_path_for(resource_name)
  #   super(resource_name)
  # end
end
