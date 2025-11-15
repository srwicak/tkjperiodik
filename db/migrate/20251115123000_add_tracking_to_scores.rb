class AddTrackingToScores < ActiveRecord::Migration[7.1]
  def change
    add_reference :scores, :first_input_by, foreign_key: { to_table: :users }, type: :bigint, index: true
    add_column :scores, :first_input_at, :datetime

    add_reference :scores, :last_edited_by, foreign_key: { to_table: :users }, type: :bigint, index: true
    add_column :scores, :last_edited_at, :datetime
  end
end
