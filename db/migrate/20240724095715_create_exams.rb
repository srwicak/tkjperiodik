class CreateExams < ActiveRecord::Migration[7.1]
  def change
    create_table :exams do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.string :short_name
      t.date :exam_date, null: false
      t.time :exam_start, null: false
      t.integer :exam_duration, null: false
      t.integer :break_time, null: false
      t.integer :size, null: false # how many participant in a batch
      t.integer :batch, null: false # how many batch in exam
      t.integer :status, null: false, default: 0
      t.text :descriptions
      t.text :notes
      t.date :start_register  # when registration for exam start
      t.date :end_register  # when registration for exam end
      t.belongs_to :created_by, foreign_key: { to_table: :users } # for who create the exam
      t.belongs_to :updated_by, foreign_key: { to_table: :users } # for who create the exam
      t.timestamps
    end

    add_index :exams, :slug, unique: true
  end
end
