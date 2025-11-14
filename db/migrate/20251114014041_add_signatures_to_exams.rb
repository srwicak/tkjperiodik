class AddSignaturesToExams < ActiveRecord::Migration[7.1]
  def change
    add_column :exams, :chairman_position, :string
    add_column :exams, :chairman_name, :string
    add_column :exams, :chairman_rank, :string
    add_column :exams, :chairman_nrp, :string
    add_column :exams, :secretary_position, :string
    add_column :exams, :secretary_name, :string
    add_column :exams, :secretary_rank, :string
    add_column :exams, :secretary_nrp, :string
  end
end
