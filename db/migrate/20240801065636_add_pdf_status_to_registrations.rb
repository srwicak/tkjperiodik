class AddPdfStatusToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :pdf_status, :integer
  end
end
