class RemoveUnusedExamColumns < ActiveRecord::Migration[7.1]
  def change
    # Remove columns from exams table that are no longer needed
    remove_column :exams, :break_time, :integer
    remove_column :exams, :batch, :integer
    remove_column :exams, :exam_duration, :integer
    remove_column :exams, :exam_rest_start, :time
    remove_column :exams, :exam_rest_end, :time
    remove_column :exams, :exam_start, :time
  end
end
