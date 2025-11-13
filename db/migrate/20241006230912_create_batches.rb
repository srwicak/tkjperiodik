class CreateBatches < ActiveRecord::Migration[7.1]
  def change
    create_table :batches do |t|
      t.references :exam, null: false, foreign_key: true
      t.integer :unit
      t.integer :registration_type
      t.text :batch_data
      t.integer :status, default: 0
      t.integer :total_count, default: 0
      t.integer :processed_count, default: 0
      t.string :slug
      t.timestamps
    end
    add_index :batches, :slug, unique: true
  end
end
