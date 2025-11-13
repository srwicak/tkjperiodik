class Manage::Exam::ParticipantsController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_participants, except: :data_session

  def show
    # BECAREFUL BETWEEN exam_session AND exam_sessions
    if @exam_session.nil?
      redirect_to edit_manage_exam_active_path(@exam.slug) and return
    end
    @created_by = @exam.created_by.user_detail.name
    @created_at = I18n.l(@exam.created_at, format: :default)
    updater = @exam.updated_by
    if updater == nil
      @updated_by = "Belum ada data"
      @updated_at = "Belum ada data"
    else
      @updated_by = @exam.updated_by.user_detail.name
      @updated_at = I18n.l(@exam.updated_at, format: :default)
    end
    @exam_sessions = @exam.exam_sessions.includes(:registrations).order(:id)

    @exam_date = I18n.l(@exam_session.start_time, format: :date_only)
    @start_time = I18n.l(@exam_session.start_time, format: :time_only)
    @end_time = I18n.l(@exam_session.end_time, format: :time_only)
  end

  def data
    unless @exam_session
      render json: { error: "Exam session not found" }, status: :not_found
      return
    end

    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    if page == 0 || size == 0
      redirect_to show_manage_exam_participant_path(@exam.slug, @exam_session.slug) and return
    end

    # Filter
    if params[:filter]
      identity = params[:filter]["0"][:value]
      filtered_registrations = @exam_session.registrations.joins(user: :user_detail)
        .where(users: { identity: identity })
        .offset(offset)
        .limit(size)
      total = 1
    else
      filtered_registrations = @exam_session.registrations.joins(user: :user_detail)
        .offset(offset)
        .limit(size)
      total = @exam_session.registrations.count
    end

    # total = filtered_registrations.count

    paginated_participants = filtered_registrations.map do |registration|
      {
        id: registration.id,
        identity: registration.user.identity,
        created_at: registration.created_at,
        name: registration.user.user_detail.name,
        user_slug: registration.user.slug,
        user_status: registration.user.account_status,
        score_slug: registration.score&.slug,
        score_number: registration.score&.score_number || "(?)",
      }
    end
    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_participants,
      total: total,
      params: params,
    }
  end

  def data_session
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    exam = Exam.find_by(slug: params[:slug])

    exam_session = ExamSession.where(exam: exam)

    sessions = exam_session
      .offset(offset)
      .limit(size)
      .order(:start_time)

    total = exam_session.count

    paginated_sessions = sessions.map do |session|
      {
        id: session.id,
        date: "#{I18n.l(session.start_time, format: :simple_no_sec)} - #{I18n.l(session.end_time, format: :time_wib)}",
        registration: "#{session.size} / #{session.max_size}",
        slug: session.slug
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_sessions,
      total: total,
    }
  end

  private

  def set_participants
    @exam = Exam.find_by(slug: params[:slug])
    unless @exam
      flash["alert"] = "Exam not found."
      redirect_to index_manage_exam_active_path and return
    end

    @exam_session = @exam.exam_sessions.find_by(slug: params[:session])
    unless @exam_session
      flash["alert"] = "Exam session not found."
      redirect_to show_manage_exam_active_path(@exam.slug) and return
    end
  end
end
