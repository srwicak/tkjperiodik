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
class ExcelUpload < ApplicationRecord
  belongs_to :exam
  validates  :unit, presence: true
  enum status: { pending: 0, processing: 1, finished: 2, error: 3 }
  include ExcelUploader::Attachment(:file)  # Shrine
end
