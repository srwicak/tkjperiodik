class AddTimeFieldsToExamSchedules < ActiveRecord::Migration[7.1]
  def change
    add_column :exam_schedules, :start_time, :time
    add_column :exam_schedules, :exam_duration, :integer
  end
end
