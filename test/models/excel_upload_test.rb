# == Schema Information
#
# Table name: excel_uploads
#
#  id         :bigint           not null, primary key
#  file_data  :text
#  status     :integer          default("pending")
#  unit       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  exam_id    :bigint           not null
#
# Indexes
#
#  index_excel_uploads_on_exam_id  (exam_id)
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#
require "test_helper"

class ExcelUploadTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
