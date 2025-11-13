class StaticController < ApplicationController
  before_action :redirect_if_verified, only: [:waiting]
  def waiting
    case current_user.account_status
    when "pending"
      @title = "Akun Anda Sedang Diverifikasi"
    when "rejected"
      @title = "Akun Anda Ditolak"
    when "suspended"
      @title = "Akun Anda Ditangguhkan"
    when "blocked"
      @title = "Akun Anda Diblokir"
    end
  end

  private

  def redirect_if_verified
    if current_user.active?
      if current_user.is_onboarded?
        redirect_to index_dashboard_path
      else
        redirect_to new_onboarding_path
      end
    end
  end
end
