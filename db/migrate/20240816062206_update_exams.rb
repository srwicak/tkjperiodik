class UpdateExams < ActiveRecord::Migration[7.1]
  def change
    remove_column :exams, :end_register, :date
    remove_column :exams, :exam_date, :date

    add_column :exams, :exam_date_start, :date
    add_column :exams, :exam_date_end, :date
    add_column :exams, :exam_rest_start, :time
    add_column :exams, :exam_rest_end, :time
  end
end
