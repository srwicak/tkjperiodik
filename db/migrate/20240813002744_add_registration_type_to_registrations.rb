class AddRegistrationTypeToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :registration_type, :integer
  end
end
