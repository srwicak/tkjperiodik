class Manage::Polda::RegionsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_region, only: %i[show edit update destroy]

  def index
    @regions = PoldaRegion.order(:name)
    @total_regions = @regions.count
  end

  def new
    @region = PoldaRegion.new
    @url = new_manage_polda_region_path
    @method = :post
  end

  def show
    @region = PoldaRegion.find_by(slug: params[:slug])
    @staffs = @region.polda_staffs
  end

  def create
    new_name = region_params[:name]
    if new_name =~ /\A\s*polda\s+/i
      slug_part = new_name.sub(/\A\s*polda\s+/i, '')
      new_slug = slug_part.parameterize
    else
      new_slug = new_name.parameterize
    end

    @region = PoldaRegion.new(region_params)
    @region.slug = new_slug

    if @region.save
      redirect_to index_manage_polda_region_path, notice: "Daerah berhasil dibuat"
    else
      @url = new_manage_polda_region_path
      @method = :post
      render :new
    end
  end

  def edit
    @url = edit_manage_polda_region_path(@region.slug)
    @method = :patch
  end

  def update
    new_name = region_params[:name]
    # Cek apakah nama diawali "Polda" (case insensitive, dengan spasi)
    if new_name =~ /\A\s*polda\s+/i
      slug_part = new_name.sub(/\A\s*polda\s+/i, '')
      new_slug = slug_part.parameterize
    else
      new_slug = new_name.parameterize
    end

    if @region.update(region_params)
      @region.update_column(:slug, new_slug) # update slug langsung, tanpa callback/validasi ulang
      redirect_to index_manage_polda_region_path, notice: "Daerah berhasil diubah"
    else
      redirect_to edit_manage_polda_region_path(@region.slug), alert: "Daerah gagal diubah."
    end
  end
  
  def destroy
    if @region.destroy
      flash[:notice] = "Daerah berhasil dihapus"
      render json: { success: true, redirect_path: index_manage_polda_region_path }
    else
      flash[:alert] = "Terjadi kesalahan saat menghapus daerah."
      render json: { success: false, error: @region.errors.full_messages.join(", "), redirect_path: index_manage_polda_region_path }, status: :unprocessable_entity
    end
  end

  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    polda_regions = PoldaRegion.all

    # Filter
    if params[:filter]
      filters = params[:filter].values
      name_filter = filters.find { |f| f[:field] == "name" }

      if name_filter
        name = name_filter[:value]
        polda_regions = polda_regions.where("name ILIKE ?", "%#{name}%")
      end
    end

    polda_count = polda_regions.count
    polda_regions = polda_regions.order(:name).offset(offset).limit(size)

    render json: {
      last_page: (polda_count / size.to_f).ceil,
      data: polda_regions.map { |region| { name: region.name, slug: region.slug } },
      total: polda_count
    }
  end

  private

  def set_region
    @region = PoldaRegion.find_by(slug: params[:slug])
  end

  def region_params
    params.require(:polda_region).permit(:name)
  end
end
