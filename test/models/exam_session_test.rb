# == Schema Information
#
# Table name: exam_sessions
#
#  id               :bigint           not null, primary key
#  end_time         :datetime         not null
#  max_size         :integer          not null
#  size             :integer          default(0), not null
#  slug             :string
#  start_time       :datetime         not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  exam_id          :bigint           not null
#  exam_schedule_id :bigint
#
# Indexes
#
#  index_exam_sessions_on_exam_id                          (exam_id)
#  index_exam_sessions_on_exam_schedule_id                 (exam_schedule_id)
#  index_exam_sessions_on_exam_schedule_id_and_start_time  (exam_schedule_id,start_time)
#  index_exam_sessions_on_slug                             (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#  fk_rails_...  (exam_schedule_id => exam_schedules.id)
#
require "test_helper"

class ExamSessionTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
