class AddNotesToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :notes, :text
  end
end
