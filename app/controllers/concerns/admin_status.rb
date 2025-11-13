module AdminStatus
  extend ActiveSupport::Concern

  included do
    before_action :authenticate_user!
  end

  def check_admin_status(redirect: false)
    is_granted = current_user.user_detail.is_operator_granted || current_user.user_detail.is_superadmin_granted

    # # TODO: OTP Mitigation
    # Comment this out if you don't want to use OTP
    # otp_required = current_user.otp_required_for_login

    # Uncomment this out if you don't want to use OTP
    otp_required = true # uncomment for mitigation

    if redirect
      unless is_granted && otp_required
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
