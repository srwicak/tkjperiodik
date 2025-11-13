class AddPdfPathToRegistrations < ActiveRecord::Migration[7.1]
  def change
    add_column :registrations, :pdf_data, :text
    add_column :registrations, :slug, :string

    add_index :registrations, :slug, unique: true
  end
end
