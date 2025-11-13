class Manage::Exam::ExcelUploadsController < ApplicationController
    before_action :set_exam_and_unit

  def index
    @upload = @exam.excel_uploads.find_by(unit: @unit)
  end

  def create
    @upload = @exam.excel_uploads.find_or_initialize_by(unit: @unit)

    # jika ada file lama, hapus
    @upload.file_attacher.destroy_previous if @upload.persisted?

    @upload.assign_attributes(
      file: params[:file],
      status: :pending
    )

    if @upload.save
      @upload.processing!
      ProcessExcelJob.perform_later(@upload)
      redirect_to show_manage_exam_unit_path(@exam.slug, @unit),
                  notice: 'File sedang diproses.'
    else
      render :index, status: :unprocessable_entity
    end
  end

  def download
    upload = @exam.excel_uploads.where(unit: @unit).finished.find(params[:id])
    send_file upload.file.download,
              filename: upload.file.original_filename,
              disposition: 'attachment'
  end

  private

  def set_exam_and_unit
    @exam = Exam.find_by!(slug: params[:slug])
    @unit = params[:unit]
  end
end
