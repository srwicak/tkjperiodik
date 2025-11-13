class UserManagementController < ApplicationController
  before_action :admin_only
  before_action :set_user_by_identity, only: [:verification_update]
  before_action :set_redis, only: [:verification_start, :verification_update, :verification_cancel]

  def verification
    data = verification_fetch.map { |item| item[:id] }
  end

  def verification_data
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    unverified_user = User.where(is_verified: false).offset(offset).limit(size)
    total_count = User.where(is_verified: false).count

    reviewers = verification_fetch

    user_with_reviewers = unverified_user.map do |user|
      user_review = reviewers.find { |reviewer| reviewer[:id] == user.id }
      user_json = user.as_json
      user_json['peninjau'] = user_review['reviewer'] if user_review
      user_json
    end

    render json: {
      last_page: (total_count.to_f / size).ceil,
      data: user_with_reviewers,
      total: total_count,
    }
  end
  def verification_start
    user_id = params[:id]
    reviewer = current_user.user_detail.name
    @redis.set("user_#{user_id}_reviewer", reviewer)

    ActionCable.server.broadcast "user_management_channel", {
      user_id: user_id,
      reviewer: current_user.user_detail.name,
      action: "verification_start"
    }

    render json: { success: true }
  end

  def verification_cancel
    user_id = params[:id]
    @redis.del("user_#{user_id}_reviewer")

    ActionCable.server.broadcast "user_management_channel", {
      user_id: user_id,
      reviewer: nil,
      action: "verification_cancel"
    }
    render json: { success: true }
  end


  def verification_update
    if @user.update(user_params)
      @redis.del("user_#{@user.id}_reviewer")
      ActionCable.server.broadcast "user_management_channel", {
        user_id: @user.id,
        reviewer: nil,
        action: "verification_update"
      }
      render json: { success: true }
    else
      render json: { success: false, error: user.errors.full_messages.join(", ") }
    end
  end

  # def review_update
  #   row_id = params[:row_id]
  #   reviewer = current_user.user_detail.name

  #   ActionCable.server.broadcast "user_management_channel", {
  #     row_id: row_id,
  #     reviewer: reviewer,
  #   }

  #   head :ok
  # end

  private

  def set_redis
    @redis ||= Redis.new(url: 'redis://localhost:6379/1')
  end

  def verification_fetch
    redis = Redis.new(url: 'redis://localhost:6379/1')
    keys = redis.keys("user_*_reviewer")
    keys.map do |key|
      user_id = key.split("_")[1]
      { id: user_id.to_i, reviewer: redis.get(key) }
    end
  end


  def user_params
    params.require(:user).permit(:is_verified, :account_status, :account_status_reason)
  end

  def admin_only
    redirect_to index_dashboard_path unless (current_user.user_detail.is_operator_granted || current_user.user_detail.is_superadmin_granted) && current_user.otp_required_for_login
    @admin = true
  end

  def set_user_by_identity
    @user = User.find_by(identity: params[:identity])
    unless @user
      render json: { success: false, error: "User not found" }, status: :not_found
    end
  end
end
