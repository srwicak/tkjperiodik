class ChangeTemplatePathToTextInLetters < ActiveRecord::Migration[7.1]
  def change
    change_column :letters, :template_path, :text
    rename_column :letters, :template_path, :template_data
  end
end
