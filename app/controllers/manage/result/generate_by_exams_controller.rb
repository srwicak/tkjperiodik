class Manage::Result::GenerateByExamsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }

  def index
    @result_template = ResultDoc.find_by!(slug: params[:slug])
    @exam = @result_template.exam
    @content = @result_template.content.nil? ? {} : JSON.parse(@result_template.content)
    @url = edit_manage_result_template_path(@result_template.slug)

    @registration_counts = count_registrations(@exam)
    @score_counts = count_scores(@exam)
    # @batches = Batch.where(exam_id: @exam.id).group(:unit)
    #                 .select('unit, COUNT(*) as batch_count, SUM(processed_count) as total_processed, SUM(total_count) as total_tasks')
    @batches = Batch.where(exam_id: @exam.id)
                    .select('batches.unit, batches.exam_id, batches.registration_type, batches.status, batches.batch_data, COUNT(*) as batch_count, SUM(processed_count) as total_processed, SUM(total_count) as total_tasks')
                    .group('batches.unit, batches.exam_id, batches.registration_type, batches.status, batches.batch_data')
  end

  def generate_docs
    exam = Exam.find(params[:exam_id])
    registration_type = params[:registration_type] == "rankup" ? 1 : 0
    unit_name = params[:unit].tr("-", " ").upcase

    # Hitung total peserta dengan score_number yang tidak null (bernilai)
    total_count = exam.registrations
                      .joins(user: :user_detail)
                      .joins("LEFT JOIN scores ON scores.registration_id = registrations.id")
                      .where(registration_type: registration_type)
                      .where(user_details: { unit: UserDetail.units[unit_name] })
                      .where.not(scores: { score_number: nil })
                      .count

    puts "Total count: #{total_count}"
    batch = Batch.create!(
      exam: exam,
      unit: UserDetail.units[unit_name],
      registration_type: registration_type,
      total_count: total_count
    )

    # Jalankan background job untuk memproses batch berdasarkan unit dan jenis pendaftaran
    BatchJob.perform_later(batch.id)

    render json: { batch_id: batch.id }
  end

  def download_docs
    slug = params[:slug]
    unit = params[:unit]
    type = params[:type]

    @batch = Batch.find_by!(exam_id: slug, unit: unit, registration_type: type)

    if @batch.batch.exists?
      send_file @batch.batch.download, filename: @batch.batch.metadata['filename'], type: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document', disposition: 'attachment'
    else
      redirect_to root_path, alert: 'Dokumen tidak ditemukan.'
    end
  end

  private

  def count_registrations(exam)
    {
      reguler: exam.registrations
                    .joins(user: :user_detail)
                    .where(registration_type: 0)
                    .group('user_details.unit')
                    .count,

      rankup: exam.registrations
                  .joins(user: :user_detail)
                  .where(registration_type: 1)
                  .group('user_details.unit')
                  .count
    }
  end

  def count_scores(exam)
    {
      reguler: exam.registrations
                    .joins(user: :user_detail)
                    .joins("LEFT JOIN scores ON scores.registration_id = registrations.id")
                    .where(is_attending: true, registration_type: 0)
                    .where.not(scores: { score_number: nil })
                    .group('user_details.unit')
                    .count,

      rankup: exam.registrations
                  .joins(user: :user_detail)
                  .joins("LEFT JOIN scores ON scores.registration_id = registrations.id")
                  .where(is_attending: true, registration_type: 1)
                  .where.not(scores: { score_number: nil })
                  .group('user_details.unit')
                  .count
    }
  end

  def check_progress
    batch = Batch.find(params[:id])
    render json: {
      total: batch.total_count,
      processed: batch.processed_count,
      status: batch.status
    }
  end
end
