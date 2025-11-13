class Superadmin::PromotesController < ApplicationController
  before_action :check_admin_status
  before_action :superadminonly
  before_action :set_superadmin, only: [:index, :promote_superadmin, :demote_superadmin]

  def index
  end

  def new
  end

  def promote_operator
    user = User.find_by!(identity: params[:identity])
    if user.user_detail
      if user.user_detail.is_operator_granted
        flash[:notice] = "Pengguna sudah sebagai Operator."
        render json: { success: false, error: "Operator already exists" }, status: :unprocessable_entity
      else
        user.user_detail.update(is_operator_granted: true)
        flash[:notice] = "Pengguna telah diaktifkan sebagai Operator."
        render json: { success: true }
      end
    else
      render json: { success: false, error: "User not found" }, status: :not_found
    end
  end

  def demote_operator
    if current_user.slug == params[:slug]
      flash[:alert] = "Anda tidak dapat menonaktifkan status Operator Anda sendiri."
      redirect_to index_superadmin_promote_path
      return
    end

    user = User.find_by!(slug: params[:slug])

    if user.user_detail
      if user.user_detail.is_superadmin_granted
        flash[:alert] = "Pengguna harus dihapus dari status Superadmin sebelum dapat dinonaktifkan sebagai Operator."
        redirect_to index_superadmin_promote_path
        return
      end

      if user.user_detail.is_operator_granted
        user.user_detail.update(is_operator_granted: false)
        flash[:notice] = "Pengguna telah dinonaktifkan sebagai Operator."
      else
        flash[:alert] = "Pengguna bukan Operator."
      end
    else
      flash[:alert] = "Pengguna tidak ditemukan."
    end

    redirect_to index_superadmin_promote_path
  end


  def promote_superadmin
    if @superadmin_count >= 3
      flash[:alert] = "Jumlah Superadmin sudah mencapai batas maksimum."
      render json: { success: false, error: "Maximum number of Superadmins reached" }, status: :unprocessable_entity
      return
    end

    user = User.find_by!(identity: params[:identity])

    if user.nil?
      flash[:alert] = "Pengguna tidak ditemukan."
      render json: { success: false, error: "User not found" }, status: :not_found
      return
    end

    if user.user_detail.is_superadmin_granted
      flash[:alert] = "Pengguna sudah menjadi Superadmin."
      render json: { success: false, error: "User is already a Superadmin" }, status: :unprocessable_entity
      return
    end

    user.user_detail.update(is_superadmin_granted: true)
    flash[:notice] = "Pengguna telah dipromosikan menjadi Superadmin."
    render json: { success: true }
  end

  def demote_superadmin
    user = User.find_by!(identity: params[:identity])
    if user.nil?
      flash[:alert] = "Pengguna tidak ditemukan."
      render json: { success: false, error: "User not found" }, status: :not_found
      return
    end

    if user.slug == current_user.slug
      flash[:alert] = "Anda tidak dapat menonaktifkan status Superadmin Anda sendiri."
      render json: { success: false, error: "Cannot demote yourself" }, status: :forbidden
      return
    end

    if !user.user_detail.is_superadmin_granted?
      flash[:notice] = "Pengguna bukan Superadmin."
      render json: { success: false, error: "User is not a Superadmin" }, status: :unprocessable_entity
      return
    end

    if @superadmin_count <= 1
      flash[:alert] = "Minimal harus ada satu Superadmin."
      render json: { success: false, error: "Cannot demote the last Superadmin" }, status: :unprocessable_entity
      return
    end

    user.user_detail.update(is_superadmin_granted: false)
    flash[:notice] = "Pengguna telah didemosi dari Superadmin."
    render json: { success: true }
  end


  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    # Filter
    if params[:filter]
      identity = params[:filter]["0"][:value]
      operators = User.includes(:user_detail)
        .where(user_details: { is_operator_granted: true }, users: { identity: identity })
        .pluck(:id, :identity, :created_at, :name, :slug, :account_status)
      paginated_users = Array.wrap(operators)
      total = 1
    else
      operators = User.includes(:user_detail)
        .where(user_details: { is_operator_granted: true })
      paginated_users = operators
        .offset(offset)
        .limit(size)
        .pluck(:id, :identity, :created_at, :name, :slug, :account_status)
      total = operators.count
    end

    paginated_users = paginated_users.map do |user|
      {
        id: user[0],
        identity: user[1],
        created_at: I18n.l(user[2], format: :default),
        name: user[3],
        slug: user[4],
        account_status: user[5],
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_users,
      total: total,
    }
  end

  def search
    user = User.find_by(identity: params[:identity])

    if user
      user_detail = user.user_detail
      if user_detail
      access_level = user_detail.is_superadmin_granted? ?  "Superadmin" : user_detail.is_operator_granted? ? "Operator" :  "Pengguna biasa"
      is_current_user = user == current_user
      render json: {
        success: true,
        user: {
          slug: user.slug,
          name: user_detail.name,
          identity: user.identity,
          is_operator: user_detail.is_operator_granted,
          is_superadmin: user_detail.is_superadmin_granted,
          access_level: access_level,
          is_current_user: is_current_user,
          is_user_detail: true
        }
      }
    else
      render json: {
          success: true,
          user: {
            slug: user.slug,
            name: "Pengguna belum menyelesaikan pendaftaran",
            access_level: "Pengguna belum menyelesaikan pendaftaran",
            identity: user.identity,
            is_user_detail: false
          }
        }
      end
    else
      render json: { success: false, message: "User not found" }, status: :not_found
    end
  end

  private

  def superadminonly
    unless current_user.user_detail.is_superadmin_granted
      redirect_to root_path
    end
  end

  def set_superadmin
    @superadmins = User.includes(:user_detail).where(user_details: { is_superadmin_granted: true })
    @superadmin_count = @superadmins.count
  end
end
