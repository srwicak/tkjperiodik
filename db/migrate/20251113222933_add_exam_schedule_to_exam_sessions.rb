class AddExamScheduleToExamSessions < ActiveRecord::Migration[7.1]
  def change
    add_reference :exam_sessions, :exam_schedule, foreign_key: true
    add_index :exam_sessions, [:exam_schedule_id, :start_time]
  end
end
