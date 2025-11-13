class CreateLetterContents < ActiveRecord::Migration[7.1]
  def change
    create_table :letter_contents do |t|
      t.references :letter, null: false, foreign_key: true
      t.string :name
      t.json :placeholder
      t.string :slug
      t.timestamps
    end
    add_index :letter_contents, :slug, unique: true
  end
end
