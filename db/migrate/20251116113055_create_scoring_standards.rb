class CreateScoringStandards < ActiveRecord::Migration[7.1]
  def change
    create_table :scoring_standards do |t|
      t.integer :golongan, null: false
      t.integer :jenis_kelamin, null: false
      t.jsonb :lookup_data, default: {}, null: false

      t.timestamps
    end
    
    add_index :scoring_standards, [:golongan, :jenis_kelamin], unique: true, name: 'index_scoring_standards_on_golongan_and_jenis_kelamin'
  end
end
