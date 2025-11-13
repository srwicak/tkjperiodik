class AddFieldsToUsers < ActiveRecord::Migration[7.1]
  def change
    # identity (encrypted) between nip or nrp
    add_column :users, :identity, :string, null: false

    # user status
    add_column :users, :is_verified, :boolean, default: false
    add_column :users, :is_onboarded, :boolean, default: false
    add_column :users, :is_forgotten, :boolean, default: false
    add_column :users, :forgotten_at, :datetime
    add_column :users, :forgotten_count, :integer, default: 0
    add_column :users, :account_status, :integer, null: false, default: 1

    # uniqueness and indexes
    add_index :users, :identity, unique: true
  end
end
