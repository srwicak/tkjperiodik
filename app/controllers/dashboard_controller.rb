class DashboardController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :check_user_status
  before_action :check_admin_status

  def index
    @police = current_user.is_police?
    today = Date.today
    @nearest_exam = Exam.where(status: :active)
      .where("DATE(start_register) <= ? AND DATE(exam_date_end) > ?", today, today)
      .order(:start_register)
      .first

    if @nearest_exam
      @start_time = @nearest_exam.start_register + 0.minute
      @end_time = ""
      @registerable = today >= @nearest_exam.start_register ? true : false

      # only warking days
      start_date = @nearest_exam.exam_date_start
      end_date = @nearest_exam.exam_date_end
      @exam_days = (start_date..end_date).count { |date| (1..5).include?(date.wday) }
    end

    if @admin
      statuses = [:rejected, :suspended, :blocked]
      @active_user = User.where(account_status: :active).count
      @unverified_user = User.where("is_verified = ? AND account_status = ?", false, 1).count
      @forgot_user = User.where(is_forgotten: true).count
      @nonactive_user = User.where(account_status: statuses).count
    end

    # 2025 update
    @polda_staff = current_user.is_polda_staff?
  end

  private

  def check_user_status
    if !user_signed_in?
      redirect_to new_user_session_path and return
    # elsif !current_user.active?
    #  redirect_to waiting_static_path and return
    elsif !current_user.is_onboarded?
      redirect_to new_onboarding_path and return

    # TODO: OTP Mitigation
    # Comment this out if you don't want to use OTP

    # elsif current_user.otp_required_for_login.nil? && (current_user.user_detail.is_operator_granted || current_user.user_detail.is_superadmin_granted)
    #   redirect_to setup_twofactorauth_path and return

    # Comment until this line if you don't want to use OTP
    end
  end
end
