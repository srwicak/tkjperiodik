# == Schema Information
#
# Table name: exams
#
#  id              :bigint           not null, primary key
#  descriptions    :text
#  exam_date_end   :date
#  exam_date_start :date
#  name            :string           not null
#  notes           :text
#  short_name      :string
#  size            :integer          not null
#  slug            :string           not null
#  start_register  :date
#  status          :integer          default("draft"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :bigint
#  updated_by_id   :bigint
#
# Indexes
#
#  index_exams_on_created_by_id  (created_by_id)
#  index_exams_on_slug           (slug) UNIQUE
#  index_exams_on_updated_by_id  (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (updated_by_id => users.id)
#
require "test_helper"

class ExamTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
