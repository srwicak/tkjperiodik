class AddUnitToExcelUploads < ActiveRecord::Migration[7.1]
  def change
    add_column :excel_uploads, :unit, :string
  end
end
