class CreateScores < ActiveRecord::Migration[7.1]
  def change
    create_table :scores do |t|
      t.references :registration, null: false, foreign_key: true, index: { unique: true }
      t.json :score_detail # json of score
      t.string :score_number # total score
      t.string :score_grade # score in grade
      t.text :result_doc_path
      t.string :slug
      t.timestamps
    end
    add_index :scores, :slug, unique: true
  end
end
