# == Schema Information
#
# Table name: polda_staffs
#
#  id              :bigint           not null, primary key
#  identity        :string
#  name            :string
#  phone           :string
#  slug            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  polda_region_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_polda_staffs_on_identity         (identity) UNIQUE
#  index_polda_staffs_on_polda_region_id  (polda_region_id)
#  index_polda_staffs_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (polda_region_id => polda_regions.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class PoldaStaffTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
