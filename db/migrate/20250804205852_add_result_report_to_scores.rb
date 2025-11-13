class AddResultReportToScores < ActiveRecord::Migration[7.1]
  def change
    add_column :scores, :result_report_data, :text
    add_column :scores, :result_report_status, :integer, default: 0
    add_column :scores, :result_report_slug, :string

    add_index :scores, :result_report_slug, unique: true
  end
end
