# == Schema Information
#
# Table name: polda_regions
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_polda_regions_on_name  (name) UNIQUE
#  index_polda_regions_on_slug  (slug) UNIQUE
#
require "test_helper"

class PoldaRegionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
