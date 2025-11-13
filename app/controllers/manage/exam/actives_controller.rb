class Manage::Exam::ActivesController < ApplicationController
  before_action :set_exam, only: [:edit, :update, :show, :destroy]
  before_action -> { check_admin_status(redirect: true) }

  def index
    @draft = Exam.where(status: 0).count
    @active = Exam.where(status: 1).count
    @archieve = Exam.where(status: 2).count
  end

  def new
    @exam = Exam.new
    @url = new_manage_exam_active_path
    @method = :post
  end

  def show
    set_info
    @units = UserDetail.units.keys
    @reg_count = @exam.registrations.count
    @att_count = @exam.registrations.where(is_attending: true).count
    @registrations_count = @exam.registrations.joins(user: :user_detail).group('user_details.unit').count
    @attendance_count = @exam.registrations.joins(user: :user_detail).where(is_attending: true).group('user_details.unit').count
  end

  def create
    @exam = Exam.new(exam_params)
    @exam.created_by = current_user
    if @exam.save
      # 2025 Update: Redirect to schedules page after creating exam
      redirect_to manage_exam_schedules_path(@exam.slug), notice: "Ujian berhasil dibuat. Silakan atur jadwal ujian per satuan."
    else
      @url = new_manage_exam_active_path
      @method = :post
      render :new
    end
  end

  def edit
    @url = edit_manage_exam_active_path(@exam.slug)
    @method = :patch
    set_info
  end

  def update
    @exam.updated_by = current_user

    if @exam.update(exam_params)
      redirect_to index_manage_exam_active_path, notice: "Ujian telah berhasil diubah"
    else
      redirect_to edit_manage_exam_active_path, alert: "Ujian gagal diubah. Mohon baca lagi: SYARAT MENGUBAH UJIAN."
    end
  end

  def destroy
    if @exam.active?
      flash[:alert] = "Tidak bisa menghapus ujian dengan status Aktif."
      render json: { success: false, redirect_path: request.referrer }, status: :unprocessable_entity
    else
      registration_exists = @exam.exam_sessions.joins(:registrations).exists?

      if registration_exists
        flash[:alert] = "Tidak bisa menghapus ujian yang telah ada pendaftarnya"
        render json: { success: false, redirect_path: request.referrer }, status: :unprocessable_entity
      else
        if @exam.destroy
          flash[:notice] = "Ujian berhasil dihapus."
          render json: { success: true, redirect_path: index_manage_exam_active_path }
        else
          flash[:alert] = "Terjadi kesalahan saat menghapus ujian."
          render json: { success: false, error: @exam.errors.full_messages.join(", "), redirect_path: index_manage_exam_active_path }, status: :unprocessable_entity
        end
      end
    end
  end

  def data
    # Pagination
    page = params[:page].to_i
    size = params[:size].to_i
    offset = (page - 1) * size

    # Filter
    if params[:filter]
      filters = params[:filter].values
      name_filter = filters.find { |f| f[:field] == "name" }
      status_filter = filters.find { |f| f[:field] == "status" }

      exams = Exam.all

      if name_filter
        name = name_filter[:value]
        exams = exams.where("name ILIKE ?", "%#{name}%")
      end

      if status_filter
        status = status_filter[:value]
        exams = exams.where(status: Exam.statuses[status])
      end

      active_exams = exams
        .order(created_at: :desc)
        .offset(offset)
        .limit(size)
        .pluck(:id, :name, :exam_date_start, :exam_date_end, :exam_start, :start_register, :notes, :status, :slug, :created_at)
      total = 1
    else
      active_exams = Exam.all
        .order(created_at: :desc)
        .offset(offset)
        .limit(size)
        .pluck(:id, :name, :exam_date_start, :exam_date_end,:exam_start, :start_register, :notes, :status, :slug, :created_at)
      total = Exam.all.count
    end

    # total = active_exams.count

    paginated_exams = active_exams.map do |exam|
      exam_date_start = I18n.l(exam[2], format: :default)
      exam_date_end = I18n.l(exam[3], format: :default)
      exam_start = I18n.l(exam[4], format: :time_only)
      start_register = I18n.l(exam[5], format: :default)
      end_register = ''
      created_at = I18n.l(exam[9], format: :simple)
      {
        id: exam[0],
        name: exam[1],
        exam_date: "#{exam_date_start} - #{exam_date_end}",
        exam_start: exam_start,
        start_register: start_register,
        end_register: end_register,
        notes: exam[6],
        status: I18n.t("exam.statuses.#{exam[7]}"),
        slug: exam[8],
        created_at: created_at,
      }
    end

    render json: {
      last_page: (total.to_f / size).ceil,
      data: paginated_exams,
      total: total,
    }
  end

  private

  def set_exam
    @exam = Exam.find_by!(slug: params[:slug])
  end

  def exam_params
    params.require(:exam).permit(:name, :short_name, :slug, :size, :batch, :break_time, :exam_date_start, :exam_date_end, :exam_start, :exam_duration, :status, :notes, :descriptions, :start_register, :exam_rest_start, :exam_rest_end)
  end

  def set_info
    if @exam.nil?
      redirect_to index_manage_exam_active_path and return
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
    @status = @exam.status
    @exam_sessions = @exam.exam_sessions.includes(:registrations).order(:id)

    # only warking days
    start_date = @exam.exam_date_start
    end_date = @exam.exam_date_end
    @exam_days = (start_date..end_date).count { |date| (1..5).include?(date.wday) }

  end
end
