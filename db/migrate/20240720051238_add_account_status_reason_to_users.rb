class AddAccountStatusReasonToUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :users, :account_status_reason, :string
  end
end
