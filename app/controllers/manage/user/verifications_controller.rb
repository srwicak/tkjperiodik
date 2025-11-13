class Manage::User::VerificationsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_redis

  def index
  end

  def update
    user = User.find(params[:id])
    unless user
      render json: { success: false, error: "User not found" }, status: :not_found
    end

    if user.update(user_params)
      render json: { success: true }
    else
      render json: { success: false, error: user.errors.full_messages.join(", ") }
    end
  end

  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    # Filter
    if params[:filter]
      identity = params[:filter]["0"][:value]
      paginated_users = User.where("(identity = ? AND is_verified = ?) OR account_status = ?", identity, false, 1).pluck(:id, :identity, :created_at)
      total = 1
    else
      unverified_users = User.where("is_verified = ? AND account_status = ?", false, 1)
      paginated_users = unverified_users
        .offset(offset)
        .limit(size)
        .pluck(:id, :identity, :created_at)
      total = unverified_users.count
    end

    paginated_users = paginated_users.map do |user|
      {
        id: user[0],
        identity: user[1],
        created_at: user[2],
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_users,
      total: total,
    }
  end

  def reviewer_fetch
    if $redis.nil?
      Rails.logger.error "Koneksi Redis tidak tersedia"
      render json: { error: "Layanan sementara tidak tersedia" }, status:   :service_unavailable
      return
    end
  
    begin
      reviewers = $redis.keys("user_*_reviewer").map do |key|
        user_id = key.split("_")[1]
        { id: user_id.to_i, reviewer: $redis.get(key) }
      end
      render json: reviewers
    rescue Redis::BaseError => e
      Rails.logger.error "Redis error in reviewer_fetch: #{e.message}"
      render json: { error: "Terjadi kesalahan saat mengakses data" }, status:   :internal_server_error
    rescue StandardError => e
      Rails.logger.error "Error in reviewer_fetch: #{e.message}"
      render json: { error: "Terjadi kesalahan saat mengambil data peninjau" },   status: :internal_server_error
    end
  end

  def reviewer_add
    user_id = params[:id]
    reviewer = current_user.user_detail.name

    @redis.set("user_#{user_id}_reviewer", reviewer)

    ActionCable.server.broadcast "user_verification_channel", {
      user_id: user_id,
      reviewer: current_user.user_detail.name,
      action: "reviewer_add",
    }

    render json: { success: true }
  end

  def reviewer_remove
    user_id = params[:id].to_i
    @redis.del("user_#{user_id}_reviewer")

    ActionCable.server.broadcast "user_verification_channel", {
      user_id: user_id,
      reviewer: nil,
      action: "reviewer_remove",
    }
    render json: { success: true }
  end

  private

  def set_redis
    @redis ||= Redis.new(url: "redis://localhost:6379/1")
  end

  def user_params
    params.require(:user).permit(:is_verified, :account_status, :account_status_reason)
  end
end
