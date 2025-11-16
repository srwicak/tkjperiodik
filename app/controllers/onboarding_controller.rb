class OnboardingController < ApplicationController
  # before_action :redirect_if_not_active, only: [:new]
  before_action :redirect_if_onboarded, only: [:new]

  def new
    @user_detail = UserDetail.new
    @available_ranks = current_user.is_police? ? UserDetail.ranks_for_police : UserDetail.ranks_for_pns
  end

  def create
    # Convert date_of_birth dari DD-MM-YYYY ke YYYY-MM-DD
    if params[:user_detail][:date_of_birth].present?
      date_str = params[:user_detail][:date_of_birth]
      if date_str.match(/^\d{2}-\d{2}-\d{4}$/)
        day, month, year = date_str.split('-')
        params[:user_detail][:date_of_birth] = "#{year}-#{month}-#{day}"
      end
    end
    
    @user_detail = current_user.build_user_detail(user_detail_params)

    ActiveRecord::Base.transaction do
      user_detail_saved = @user_detail.save!
      user_updated = current_user.update!(user_params.merge(is_onboarded: true, is_verified: true, account_status: 0))

      if user_detail_saved && user_updated
        redirect_to index_dashboard_path, notice: "Data diri anda telah disimpan"
      else
        raise ActiveRecord::Rollback
      end
    end

  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotSaved
    Rails.logger.error("Error saving user detail: " + @user_detail.errors.full_messages.join(", "))
    Rails.logger.error("Error updating user: " + current_user.errors.full_messages.join(", "))

    unless current_user.errors[:email].empty?
      @user_detail.errors.add(:email, "telah digunakan. Masukkan email lain")
    end

    @available_ranks = current_user.is_police? ? UserDetail.ranks_for_police : UserDetail.ranks_for_pns
    render :new, status: :unprocessable_entity
  end

  private

  def redirect_if_not_active
    redirect_to waiting_static_path unless current_user.active?
  end

  def redirect_if_onboarded
    redirect_to index_dashboard_path if current_user.is_onboarded? && !current_user.user_detail.nil?
  end

  def user_detail_params
    params.require(:user_detail).permit(:name, :gender, :position, :rank, :unit, :date_of_birth)
  end

  def user_params
    params.require(:user_detail).permit(:email)
  end
end
