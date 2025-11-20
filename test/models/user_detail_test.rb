# == Schema Information
#
# Table name: user_details
#
#  id                    :bigint           not null, primary key
#  date_of_birth         :date
#  gender                :boolean          not null
#  is_operator_active    :boolean          default(TRUE), not null
#  is_operator_granted   :boolean          default(FALSE), not null
#  is_superadmin_granted :boolean          default(FALSE), not null
#  name                  :string           default(""), not null
#  person_status         :integer          not null
#  position              :string
#  rank                  :integer
#  unit                  :integer
#  work_schedule         :jsonb
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint
#
# Indexes
#
#  index_user_details_on_user_id  (user_id)
#
require "test_helper"

class UserDetailTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
