class RenameSignatureColumnsToFormAFormB < ActiveRecord::Migration[7.1]
  def change
    # Rename chairman -> form_a
    rename_column :exams, :chairman_position, :form_a_position
    rename_column :exams, :chairman_name, :form_a_name
    rename_column :exams, :chairman_rank, :form_a_rank
    rename_column :exams, :chairman_nrp, :form_a_nrp
    
    # Rename secretary -> form_b
    rename_column :exams, :secretary_position, :form_b_position
    rename_column :exams, :secretary_name, :form_b_name
    rename_column :exams, :secretary_rank, :form_b_rank
    rename_column :exams, :secretary_nrp, :form_b_nrp
  end
end
