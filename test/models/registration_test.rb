# == Schema Information
#
# Table name: registrations
#
#  id                :bigint           not null, primary key
#  is_attending      :boolean
#  pdf_data          :text
#  pdf_status        :integer
#  registration_type :integer
#  slug              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exam_session_id   :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_registrations_on_exam_session_id              (exam_session_id)
#  index_registrations_on_slug                         (slug) UNIQUE
#  index_registrations_on_user_id                      (user_id)
#  index_registrations_on_user_id_and_exam_session_id  (user_id,exam_session_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_session_id => exam_sessions.id)
#  fk_rails_...  (user_id => users.id)
#
require "test_helper"

class RegistrationTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
