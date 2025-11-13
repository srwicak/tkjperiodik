class CreateExcelUploads < ActiveRecord::Migration[7.1]
  def change
create_table :excel_uploads do |t|
      t.references :exam, null: false, foreign_key: true
      t.integer    :status, default: 0   # enum: pending processing finished error
      t.text       :file_data            # Shrine
      t.timestamps
    end
  end
end
