# == Schema Information
#
# Table name: letters
#
#  id            :bigint           not null, primary key
#  slug          :string
#  template_data :text
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  exam_id       :bigint           not null
#
# Indexes
#
#  index_letters_on_exam_id  (exam_id)
#  index_letters_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#
require "test_helper"

class LetterTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
