class AddDocStatusToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :doc_status, :integer
  end
end
