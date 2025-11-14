class AddGolonganToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :golongan, :integer
  end
end
