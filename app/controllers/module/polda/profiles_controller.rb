class Module::Polda::ProfilesController < ApplicationController
  before_action :set_polda_staff_profile

  def edit
    @url = edit_module_polda_staff_profile_path
  end

  def update
    if @polda_staff.update(polda_staff_params)
      redirect_to edit_module_polda_staff_profile_path, notice: "Profile telah diperbarui"
    else
      flash.now[:alert] = "Gagal memperbarui profile"
      render :edit
    end
  end

  private

  def polda_staff_params
    params.require(:polda_staff).permit(:name, :identity, :phone)
  end

  def set_polda_staff_profile
    @polda_staff = current_user.polda_staff
  end
end
