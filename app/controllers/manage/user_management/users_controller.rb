class Manage::UserManagement::UsersController < ApplicationController
  before_action :check_admin_status

  def new
    @user = User.new
    @user.build_user_detail
    @url = new_manage_user_path
  end

  def create
    @user = User.new(user_params.merge(account_status: 0, is_verified: true, is_onboarded: true))
    if @user.save
      redirect_to new_manage_user_path, notice: "Pengguna telah ditambahkan"
    else
      redirect_to new_manage_user_path, alert: "Pengguna gagal ditambahkan, perhatikan data yang dimasukkan"
    end
  end

  private

  def user_params
    params.require(:user).permit(:identity, :password, user_detail_attributes: [:name, :date_of_birth, :rank, :unit, :position, :gender])
  end
end
