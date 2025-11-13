class AddDateOfBirthToUserDetails < ActiveRecord::Migration[7.1]
  def change
    add_column :user_details, :date_of_birth, :date
  end
end
