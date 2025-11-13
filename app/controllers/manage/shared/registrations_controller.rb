class Manage::Shared::RegistrationsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  def show
    @registration = Registration.find_by!(slug: params[:slug])
    @exam_session = @registration.exam_session
    @exam = @exam_session.exam
    @score = @registration.score

    @thescore = @score.is_scored? ? "Belum dinilai" : "#{@score.score_number} (#{@score.score_grade})"
    @is_scored = @score.is_scored? ? "Penilaian belum dilakukan" : "Penilaian telah dilakukan"
    @when_scored = @score.is_scored? ? "Penilaian belum  dilakukan" : I18n.l(@score.updated_at, format: :default)
  end

  def data
    user_slug = params[:slug]
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    query = Registration.joins(exam_session: :exam)
      .joins(:user)
      .left_joins(:score)
      .where(users: { slug: user_slug })

    # Filter
    if params[:filter]
      exam_name = params[:filter]["0"][:value]
      query = query.where("exams.name ILIKE ?", "%#{exam_name}%")
    end

    total_count = query.count

    registrations = query.offset(offset)
      .limit(size)

    registrations_data = registrations.map do |registration|
      exam = registration.exam_session.exam
      score = registration.score
      {
        id: registration.id,
        exam_name: exam.name,
        exam_date: "#{I18n.l(registration.exam_session.start_time, format: :date_only)}",
        registration_date: I18n.l(registration.created_at, format: :simple),
        start_time: I18n.l(registration.exam_session.start_time, format: :time_only),
        end_time: I18n.l(registration.exam_session.end_time, format: :time_only),
        slug: registration.slug,
        score_number: score&.score_number || "(?)",
        score_slug: score&.slug,
      }
    end

    render json: {
      last_page: (total_count.to_f / size).ceil,
      data: registrations_data,
      total: total_count
    }

  end
end
