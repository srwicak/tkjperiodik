class Manage::Exam::UnitsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_participants

  def show
    @registration_counts = count_registrations(@exam)
    @score_counts = count_scores(@exam)
    @upload = @exam.excel_uploads.find_by(unit: params[:unit])
  end

  def data
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size
    unit_name = params[:unit].tr("-", " ").upcase
    registration_type = params[:registration_type]

    # Cari berdasarkan slug dari exam
    exam = Exam.find_by!(slug: params[:slug])

    # Query dasarnya: cari berdasarkan exam dan unit
    registrations = Registration
                      .joins(:exam_session)
                      .joins(user: :user_detail)
                      .joins("LEFT JOIN scores ON scores.registration_id = registrations.id")
                      .where(exam_sessions: { exam_id: exam.id })
                      .where(user_details: { unit: UserDetail.units[unit_name] })

    # Filter berdasarkan registration_type jika diberikan
    if registration_type.present?
      registrations = registrations.where(registration_type: Registration.registration_types[registration_type])
    end

    # Pisahkan peserta yang sudah memiliki nilai dan yang belum
    if params[:with_score] == "true"
      registrations = registrations.where.not(scores: { score_number: nil })
    else
      registrations = registrations.where(scores: { score_number: nil })
    end

    # Pagination
    paginated_registrations = registrations
                                .order(created_at: :desc)
                                .offset(offset)
                                .limit(size)
                                .select("registrations.*, scores.score_number, users.slug AS user_slug, scores.slug AS score_slug, users.account_status")

    # Format data untuk JSON response
    render json: {
      data: format_registrations(paginated_registrations),
      last_page: (registrations.count.to_f / size).ceil
    }
  end

  private

  def format_registrations(registrations)
    registrations.map do |reg|
      {
        identity: reg.user.identity,
        name: reg.user.user_detail.name,
        score_number: reg.score_number,
        created_at: reg.created_at,
        user_slug: reg.user_slug,
        score_slug: reg.score_slug,
        user_status: reg.user.account_status,
      }
    end
  end
  def set_participants
    @exam = Exam.find_by(slug: params[:slug])
    @unit = params[:unit].tr("-", " ").upcase

    @participants = Registration
                      .joins(user: :user_detail)
                      .joins(exam_session: :exam)
                      .where(exam_sessions: { exam_id: @exam.id })
                      .where(user_details: { unit: UserDetail.units[@unit] })

  end

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
        .where(is_attending: true, registration_type: 0) # pastikan ini untuk reguler
        .where.not(scores: { score_number: nil })
        .group('user_details.unit')
        .count,

      rankup: exam.registrations
        .joins(user: :user_detail)
        .joins("LEFT JOIN scores ON scores.registration_id = registrations.id")
        .where(is_attending: true, registration_type: 1) # pastikan ini untuk rankup
        .where.not(scores: { score_number: nil })
        .group('user_details.unit')
        .count
    }
  end
end
