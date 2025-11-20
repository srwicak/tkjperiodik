class AddOperatorStatusToUserDetails < ActiveRecord::Migration[7.1]
  def change
    add_column :user_details, :is_operator_active, :boolean, default: true, null: false
    add_column :user_details, :work_schedule, :jsonb, default: {}
  end
end
