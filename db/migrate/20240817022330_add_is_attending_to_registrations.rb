class AddIsAttendingToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :is_attending, :boolean
  end
end
