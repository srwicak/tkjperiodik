class Module::HistoriesController < ApplicationController
  before_action :check_admin_status
  before_action :set_registration, only: %i[show download_pdf]
  before_action :authorize_user, only: [:download_pdf]
  def index
    @registrations = Registration.where(user: current_user).order(created_at: :desc)
  end

  def show
    @score = @registration.score
  end

  def download_pdf
    if @registration.completed?
      send_file @registration.pdf.download, filename: @registration.pdf.metadata['filename'], type: 'application/pdf', disposition: 'attachment'
    else
      GeneratePdfJob.perform_now(@registration.id)
      redirect_to download_pdf_module_history_path(@registration.slug), notice: 'PDF berhasil dibuat, sedang mengunduh...'
    end
  end

  # def trigger_pdf_creation
  #   @registration = Registration.find_by!(slug: params[:slug])

  #   if @registration.completed?
  #     redirect_to download_pdf_module_history_path(@registration.slug), notice: "PDF sudah tersedia. Klik untuk mengunduh."
  #   else
  #     GeneratePdfJob.new(@registration.id).call
  #     redirect_to show_module_history_path(@registration.slug), notice: "Permintaan pembuatan PDF telah diproses. Silakan periksa kembali setelah beberapa saat."
  #   end
  # end

  private

  def set_registration
    @registration = Registration.find_by!(slug: params[:slug])
  end


  def authorize_user
    unless current_user == @registration.user || current_user.admin?
      redirect_to root_path, alert: 'Anda tidak memiliki izin untuk mengakses file ini.'
    end
  end
end
