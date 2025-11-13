class ChangeResultDocPathToTextInScores < ActiveRecord::Migration[7.1]
  def change
    change_column :scores, :result_doc_path, :text
    rename_column :scores, :result_doc_path, :result_doc_data
  end
end
