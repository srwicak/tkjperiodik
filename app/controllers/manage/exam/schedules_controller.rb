class Manage::Exam::SchedulesController < ApplicationController
  before_action -> { check_admin_status(redirect: true) }
  before_action :set_exam
  before_action :set_schedule, only: [:edit, :update, :destroy]

  def index
    @schedules = @exam.exam_schedules.order(:exam_date)
  end

  def new
    @schedule = @exam.exam_schedules.build
  end

  def create
    @schedule = @exam.exam_schedules.build(schedule_params)

    if @schedule.save
      redirect_to manage_exam_schedules_path(@exam), notice: "Jadwal ujian berhasil ditambahkan."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
  end

  def update
    if @schedule.update(schedule_params)
      redirect_to manage_exam_schedules_path(@exam), notice: "Jadwal ujian berhasil diperbarui."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    if @schedule.registrations.exists?
      redirect_to manage_exam_schedules_path(@exam), alert: "Tidak bisa menghapus jadwal yang sudah ada pendaftarnya."
    else
      @schedule.destroy
      redirect_to manage_exam_schedules_path(@exam), notice: "Jadwal ujian berhasil dihapus."
    end
  end

  private

  def set_exam
    @exam = Exam.find_by!(slug: params[:exam_slug])
  end

  def set_schedule
    @schedule = @exam.exam_schedules.find_by!(slug: params[:id])
  end

  def schedule_params
    params.require(:exam_schedule).permit(:exam_date, :schedule_name, :max_participants, :notes, units: [])
  end
end
