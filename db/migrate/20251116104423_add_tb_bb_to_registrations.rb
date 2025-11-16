class AddTbBbToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :tb, :integer
    add_column :registrations, :bb, :integer
  end
end
