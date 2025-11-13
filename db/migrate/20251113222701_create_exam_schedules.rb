class CreateExamSchedules < ActiveRecord::Migration[7.1]
  def change
    create_table :exam_schedules do |t|
      t.references :exam, null: false, foreign_key: true
      t.date :exam_date, null: false
      t.string :schedule_name
      t.integer :units, array: true, default: []
      t.integer :max_participants
      t.text :notes
      t.string :slug

      t.timestamps
    end

    add_index :exam_schedules, [:exam_id, :exam_date]
    add_index :exam_schedules, :units, using: 'gin'
    add_index :exam_schedules, :slug, unique: true
  end
end
