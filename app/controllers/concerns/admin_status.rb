module AdminStatus
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def check_admin_status(redirect: false)
    is_granted = current_user.user_detail.is_operator_granted || current_user.user_detail.is_superadmin_granted

    # Check if operator access is allowed (active and within schedule)
    # Superadmin always has access regardless of schedule
    if current_user.user_detail.is_operator_granted && !current_user.user_detail.is_superadmin_granted
      is_granted = current_user.user_detail.operator_access_allowed?
    end

    # # TODO: OTP Mitigation
    # Comment this out if you don't want to use OTP
    # otp_required = current_user.otp_required_for_login

    # Uncomment this out if you don't want to use OTP
    otp_required = true # uncomment for mitigation

    if redirect
      unless is_granted && otp_required
        if current_user.user_detail.is_operator_granted && !current_user.user_detail.operator_access_allowed?
          flash[:alert] = "Akses operator Anda sedang dinonaktifkan atau di luar jam kerja yang ditentukan."
        end
        redirect_to index_dashboard_path
        return
      end
      @admin = is_granted
      @super_admin = current_user.user_detail.is_superadmin_granted
    else
      @admin = is_granted
      @super_admin = current_user.user_detail.is_superadmin_granted
    end
  end
end
