class CreatePoldaRegions < ActiveRecord::Migration[7.1]
  def change
    create_table :polda_regions do |t|
      t.string :name
      t.string :slug

      t.timestamps
    end
    add_index :polda_regions, :name, unique: true
    add_index :polda_regions, :slug, unique: true
  end
end
