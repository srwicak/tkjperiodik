class CreatePoldaStaffs < ActiveRecord::Migration[7.1]
  def change
    create_table :polda_staffs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :polda_region, null: false, foreign_key: true
      t.string :name, null: true
      t.string :phone, null: true
      t.string :identity, null: true
      t.string :slug

      t.timestamps
    end
    add_index :polda_staffs, :identity, unique: true
  end
end
