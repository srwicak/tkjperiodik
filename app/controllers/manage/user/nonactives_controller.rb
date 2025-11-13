class Manage::User::NonactivesController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_user, only: [:show, :update, :destroy]

  def index
  end

  def show
    statuses = [:rejected, :suspended, :blocked]
    user = User.joins(:user_detail).select(:id, :identity, :created_at, :updated_at, :name, :position, :unit, :rank, :gender, :account_status, :account_status_reason).where(slug: @slug, account_status: statuses).first

    if user.nil?
      user = User.select(:identity, :created_at, :updated_at, :account_status).where(slug: @slug, account_status: statuses).first
      @identity = user.identity
      is_police = user.is_police?
      @id_cat = is_police ? "NRP" : "NIP"
      @name = @identity + " - (Belum mengisi profil)"
      @personal = [
        { key: @id_cat, value: @identity },
        { key: "Keanggotaan", value: "Belum mengisi profil" },
        { key: "Gender", value: "Belum mengisi profil" },
      ]

      register_date = I18n.l(user.created_at, format: :default)
      update_date = I18n.l(user.updated_at, format: :default)

      @status = user.formatted_account_status

      @account = [
        { key: "Status", value: @status },
        { key: "Daftar", value: register_date },
        { key: "Perubahan", value: update_date },
        { key: "Akses", value: "Belum mengisi profil" },
      ]
      return
    end

    @identity = user.identity
    is_police = user.is_police?
    @id_cat = is_police ? "NRP" : "NIP"

    register_date = I18n.l(user.created_at, format: :default)
    update_date = I18n.l(user.updated_at, format: :default)

    gender = user.user_detail.gender ? "PRIA" : "WANITA"

    @name = user.user_detail.name
    @personal = [
      { key: @id_cat, value: @identity },
      { key: "Keanggotaan", value: user.user_detail.formatted_person_profile },
      { key: "Gender", value: gender },
    ]

    if is_police
      @police = [
        { key: "Kesatuan", value: user.user_detail.unit },
        { key: "Pangkat", value: user.user_detail.rank },
        { key: "Jabatan", value: user.user_detail.position },
      ]
    end

    @is_operator = user.user_detail.is_operator_granted?
    access = @is_operator ? "Operator" : "Pengguna Biasa"

    @is_registered_exists = !user.registration.empty?

    @status = user.formatted_account_status
    @comment = user.account_status_reason

    @account = [
      { key: "Status", value: @status },
      { key: "Daftar", value: register_date },
      { key: "Perubahan", value: update_date },
      { key: "Akses", value: access },
    ]
  end

  def update
    user = User.find_by(slug: @slug)
    unless user
      render json: { success: false, error: "User not found" }, status: :not_found
    end

    if user.update(user_params)
      render json: { success: true }
    else
      render json: { success: false, error: user.errors.full_messages.join(", ") }
    end
  end

  def destroy
    user = User.find_by(slug: @slug)
    if user.user_detail.nil? || !user.user_detail.is_operator_granted? || user.registration.empty?
      if user.destroy
        render json: { success: true }
      else
        render json: { success: false, error: user.errors.full_messages.join(", ") }
      end
    else
      render json: { success: false, error: "User cannot be destroyed" }
    end
  end

  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    statuses = [:rejected, :suspended, :blocked]

    # Filter
    if params[:filter]
      identity = params[:filter]["0"][:value]
      active_users = User.includes(:user_detail).where(identity: identity, account_status: statuses).pluck(:id, :identity, :created_at, :updated_at, :name, :account_status, :slug)
      paginated_users = Array.wrap(active_users)
      total = 1
    else
      active_users = User.includes(:user_detail).where(account_status: statuses).order(updated_at: :desc)
      paginated_users = active_users
        .offset(offset)
        .limit(size)
        .pluck(:id, :identity, :created_at, :updated_at, :name, :account_status, :slug)
      total = active_users.count
    end

    paginated_users = paginated_users.map do |user|
      status = {
        "rejected" => "Ditolak",
        "suspended" => "Ditangguhkan",
        "blocked" => "Diblokir",
      }[user[5]]

      {
        id: user[0],
        identity: user[1],
        created_at: user[2],
        updated_at: user[3],
        name: user[4],
        account_status: status,
        slug: user[6]
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_users,
      total: total,
    }
  end

  private
  def set_user
    @slug = params[:slug]
    statuses = [:rejected, :suspended, :blocked]
    redirect_to index_manage_user_nonactive_path unless User.exists?(slug: @slug, account_status: statuses)
  end

  def user_params
    params.require(:user).permit(:account_status, :account_status_reason)
  end
end
