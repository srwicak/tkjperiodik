class AddAllowOnspotRegistrationToExams < ActiveRecord::Migration[7.1]
  def change
    add_column :exams, :allow_onspot_registration, :boolean, default: false, null: false
  end
end
