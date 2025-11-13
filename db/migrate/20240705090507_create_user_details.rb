class CreateUserDetails < ActiveRecord::Migration[7.1]
  def change
    create_table :user_details do |t|
      # relationship
      t.belongs_to :user, index: true

      # personnel details
      # rank = pangkat
      # unit = satuan kerja
      # position = jabatan
      t.string :name, null: false, default: ""
      t.integer :rank
      t.string :position
      t.integer :unit
      t.boolean :gender, null: false

      # role related details
      t.boolean :is_operator_granted, null: false, default: false
      t.boolean :is_superadmin_granted, null: false, default: false

      # user status
      t.integer :person_status, null: false #police/staff
      t.timestamps
    end
  end
end
