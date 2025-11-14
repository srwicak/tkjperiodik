class UpdateSignatureColumnsToFiveFields < ActiveRecord::Migration[7.1]
  def change
    # Rename form_a_position -> form_a_police_position
    rename_column :exams, :form_a_position, :form_a_police_position
    # Tambah kolom form_a_event_position (opsional)
    add_column :exams, :form_a_event_position, :string
    
    # Rename form_b_position -> form_b_police_position
    rename_column :exams, :form_b_position, :form_b_police_position
    # Tambah kolom form_b_event_position (opsional)
    add_column :exams, :form_b_event_position, :string
  end
end
