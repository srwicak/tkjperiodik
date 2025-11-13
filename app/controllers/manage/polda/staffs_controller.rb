class Manage::Polda::StaffsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  # def index
  # end

  # def show
  # end

  # def new
  #   @staff = PoldaStaff.new
  # end

  def create
    polda_region = PoldaRegion.find_by(slug: params[:slug])

    username = Array.new(6) { rand(0..9) }.join
    password = SecureRandom.hex(8)

    polda_user = User.create!(
      identity: username,
      password: password,
      password_confirmation: password,
      is_verified: true,
      is_onboarded: true,
      account_status: :active,
      user_detail_attributes: {
        name: "Staff #{polda_region.name}",
        person_status: :polda_staff,
        gender: true, # assume male, because this column mandatory
      }
    )

    polda_staff = PoldaStaff.new(
      user: polda_user,
      polda_region: polda_region
    )

    polda_staff.save!
    flash[:notice] = "User berhasil dibuat. Mohon diinforkasikan ke penanggung jawab Polda terkait"
    redirect_to show_manage_polda_region_path(slug: polda_region.slug)
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Failed to create PoldaStaff: #{e.message}"
    flash[:alert] = "Gagal membuat user."
    render :new
  end

  # def edit
  # end

  # def update
  # end

  # def destroy
  # end
end
