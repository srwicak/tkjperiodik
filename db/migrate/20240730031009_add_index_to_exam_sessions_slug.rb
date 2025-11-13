class AddIndexToExamSessionsSlug < ActiveRecord::Migration[7.1]
  def change
    add_index :exam_sessions, :slug, unique: true
  end
end
