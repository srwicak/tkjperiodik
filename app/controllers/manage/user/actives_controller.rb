class Manage::User::ActivesController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_user, only: [:show, :update, :edit_profile, :update_profile]

  def index
  end

  def show
    user = User.joins(:user_detail).select(:id, :identity, :created_at, :updated_at, :name, :position, :unit, :rank, :gender, :account_status).where(slug: @slug, account_status: :active).first

    if user.nil?
      user = User.select(:identity, :created_at, :updated_at, :account_status).where(slug: @slug, account_status: :active).first
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

      @account = [
        { key: "Status", value: user.formatted_account_status },
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

    is_operator = user.user_detail.is_operator_granted? ? "Operator" : "Pengguna Biasa"

    @account = [
      { key: "Status", value: user.formatted_account_status },
      { key: "Daftar", value: register_date },
      { key: "Perubahan", value: update_date },
      { key: "Akses", value: is_operator },
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

  def edit_profile
    user = User.includes(:user_detail).find_by(slug: @slug, account_status: :active)
    
    unless user
      redirect_to index_manage_user_active_path, alert: "User tidak ditemukan"
      return
    end

    @user = user
    @user_detail = user.user_detail
    @available_ranks = user.is_police? ? UserDetail.ranks_for_police : UserDetail.ranks_for_pns
    
    render json: {
      name: @user_detail.name,
      date_of_birth: @user_detail.date_of_birth&.strftime('%d-%m-%Y'),
      rank: @user_detail.rank,
      unit: @user_detail.unit,
      position: @user_detail.position,
      gender: @user_detail.gender,
      available_ranks: @available_ranks.keys,
      available_units: UserDetail.units.keys
    }
  end

  def update_profile
    user = User.includes(:user_detail).find_by(slug: @slug, account_status: :active)
    
    unless user
      render json: { success: false, error: "User tidak ditemukan" }, status: :not_found
      return
    end

    # Convert date_of_birth dari DD-MM-YYYY ke YYYY-MM-DD jika ada
    if profile_params[:date_of_birth].present?
      date_str = profile_params[:date_of_birth]
      if date_str.match(/^\d{2}-\d{2}-\d{4}$/)
        day, month, year = date_str.split('-')
        profile_params[:date_of_birth] = "#{year}-#{month}-#{day}"
      end
    end

    if user.user_detail.update(profile_params)
      render json: { success: true, message: "Profil peserta berhasil diperbarui" }
    else
      render json: { success: false, error: user.user_detail.errors.full_messages.join(", ") }, status: :unprocessable_entity
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
      active_users = User.includes(:user_detail).where(identity: identity, account_status: :active).pluck(:id, :identity, :created_at, :name, :slug)
      paginated_users = Array.wrap(active_users)
      total = 1
    else
      active_users = User.includes(:user_detail).where(account_status: :active)
      paginated_users = active_users
        .order('created_at ASC')
        .offset(offset)
        .limit(size)
        .pluck(:id, :identity, :created_at, :name, :slug)
      total = active_users.count
    end

    paginated_users = paginated_users.map do |user|
      {
        id: user[0],
        identity: user[1],
        created_at: user[2],
        name: user[3],
        slug: user[4],
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
    redirect_to index_manage_user_active_path unless User.exists?(slug: @slug, account_status: :active)
  end

  def user_params
    params.require(:user).permit(:account_status, :account_status_reason)
  end

  def profile_params
    params.require(:user_detail).permit(:name, :rank, :unit, :position, :gender, :date_of_birth)
  end
end
