class Manage::User::ForgotsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }

  def index
  end

  def update
    user = User.find(params[:id])
    unless user
      render json: { success: false, error: "User not found" }, status: :not_found
    end

    if user.update(user_params.merge(forgotten_at: nil, forgotten_count: 0, account_status: :active))
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
      paginated_users = User.where(identity: identity, is_forgotten: true).pluck(:id, :identity, :created_at, :forgotten_at)
      total = 1
    else
      unverified_users = User.where(is_forgotten: true).order(forgotten_at: :asc)
      paginated_users = unverified_users
        .offset(offset)
        .limit(size)
        .pluck(:id, :identity, :created_at, :forgotten_at)
      total = unverified_users.count
    end

    paginated_users = paginated_users.map do |user|
      {
        id: user[0],
        identity: user[1],
        created_at: user[2],
        forgotten_at: user[3],
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_users,
      total: total,
    }
  end

  private

  def user_params
    params.require(:user).permit(:is_forgotten)
  end
end
