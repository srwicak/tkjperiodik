class UpdateExamScheduleTimeFields < ActiveRecord::Migration[7.1]
  def change
    # Tambah end_time dan exam_date_end untuk support range
    add_column :exam_schedules, :end_time, :time
    add_column :exam_schedules, :exam_date_end, :date
    
    # Remove exam_duration karena sekarang pakai start_time & end_time
    remove_column :exam_schedules, :exam_duration, :integer
  end
end
