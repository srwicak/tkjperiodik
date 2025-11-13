class AddCodeToScore < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :code, :string

    add_index :scores, :code, unique: true
  end
end
