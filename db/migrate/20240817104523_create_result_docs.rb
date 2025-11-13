class CreateResultDocs < ActiveRecord::Migration[7.1]
  def change
    create_table :result_docs do |t|
      t.references :exam, null: false, foreign_key: true
      t.jsonb :content
      t.string :slug
      t.timestamps
    end
  end
end
