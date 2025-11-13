class CreateLetters < ActiveRecord::Migration[7.1]
  def change
    create_table :letters do |t|
      t.references :exam, null: false, foreign_key: true
      t.string :template_path
      t.string :slug
      t.timestamps
    end

    add_index :letters, :slug, unique: true
  end
end
