class AddIndexToUsersAccountStatus < ActiveRecord::Migration[7.1]
  def change
    add_index :users, :account_status
  end
end
