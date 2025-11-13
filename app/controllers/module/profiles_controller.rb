class Module::ProfilesController < ApplicationController
  before_action :check_admin_status
  before_action :set_profile
  def edit
    @url = edit_module_profile_path
  end

  def update
    # Convert date_of_birth dari DD-MM-YYYY ke YYYY-MM-DD jika ada
    if params[:user_detail][:date_of_birth].present?
      date_str = params[:user_detail][:date_of_birth]
      if date_str.match(/^\d{2}-\d{2}-\d{4}$/)
        day, month, year = date_str.split('-')
        params[:user_detail][:date_of_birth] = "#{year}-#{month}-#{day}"
      end
    else
      # Jika tanggal lahir kosong, hapus dari params agar tidak di-update
      params[:user_detail].delete(:date_of_birth)
    end
    
    if @user_detail.update(user_detail_params)
      if user_params[:password].present?
        if current_user.update_with_password(user_params)
          redirect_to edit_module_profile_path, notice: "Profile dan kata sandi telah diperbarui"
        else
          redirect_to edit_module_profile_path, alert: "Gagal memperbarui kata sandi"
        end
      else
        redirect_to edit_module_profile_path, notice: "Profile telah diperbarui"
      end
    else
      render :edit
    end
  end

  private

  def user_detail_params
    params.require(:user_detail).permit(:name, :rank, :unit, :position, :gender, :date_of_birth)
  end

  def user_params
    params.require(:user_detail).permit(:current_password, :password, :password_confirmation)
  end

  def set_profile
    @user_detail = current_user.user_detail
  end
end
