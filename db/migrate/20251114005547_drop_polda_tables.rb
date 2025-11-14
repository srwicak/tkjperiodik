class DropPoldaTables < ActiveRecord::Migration[7.1]
  def up
    # Drop polda tables
    drop_table :polda_reports, if_exists: true
    drop_table :polda_staffs, if_exists: true
    drop_table :polda_regions, if_exists: true
  end

  def down
    # Recreate tables if needed for rollback
    create_table :polda_regions do |t|
      t.string :name
      t.string :slug
      t.timestamps
    end
    add_index :polda_regions, :name, unique: true
    add_index :polda_regions, :slug, unique: true

    create_table :polda_staffs do |t|
      t.references :user, null: false, foreign_key: true
      t.references :polda_region, null: false, foreign_key: true
      t.string :name
      t.string :phone
      t.string :identity
      t.string :slug
      t.timestamps
    end
    add_index :polda_staffs, :identity, unique: true

    create_table :polda_reports do |t|
      t.references :polda_region, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :file_data
      t.string :slug, null: false
      t.timestamps
    end
    add_index :polda_reports, :slug, unique: true
  end
end
