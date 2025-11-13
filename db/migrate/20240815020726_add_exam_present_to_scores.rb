class AddExamPresentToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :exam_present, :boolean, default: false
  end
end
