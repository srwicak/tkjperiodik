class CreateExamSessions < ActiveRecord::Migration[7.1]
  def change
    create_table :exam_sessions do |t|
      t.references :exam, null: false, foreign_key: true
      t.datetime :start_time, null: false
      t.datetime :end_time, null: false
      t.integer :size, null: false, default: 0
      t.integer :max_size, null: false
      t.string :slug
      t.timestamps
    end
  end
end
