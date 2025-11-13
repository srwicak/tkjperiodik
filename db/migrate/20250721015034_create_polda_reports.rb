class CreatePoldaReports < ActiveRecord::Migration[7.1]
  def change
    create_table :polda_reports do |t|
      t.references :polda_region, null: false, foreign_key: true
      t.references :exam, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.string :title, null: false
      t.text :description
      t.text :file_data
      t.string :slug, null: false, index: { unique: true }
      t.timestamps
    end
  end
end
