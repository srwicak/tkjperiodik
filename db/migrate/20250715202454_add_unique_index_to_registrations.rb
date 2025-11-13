class AddUniqueIndexToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_index :registrations, [:user_id, :exam_session_id], unique: true
  end
end
