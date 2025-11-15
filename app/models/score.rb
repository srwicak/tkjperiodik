# == Schema Information
#
# Table name: scores
#
#  id                   :bigint           not null, primary key
#  code                 :string
#  doc_status           :integer
#  exam_present         :boolean          default(FALSE)
#  first_input_at       :datetime
#  last_edited_at       :datetime
#  notes                :text
#  result_doc_data      :text
#  result_report_data   :text
#  result_report_slug   :string
#  result_report_status :integer          default("idle")
#  score_detail         :json
#  score_grade          :string
#  score_number         :string
#  slug                 :string
#  created_at           :datetime         not null
#  updated_at           :datetime         not null
#  first_input_by_id    :bigint
#  last_edited_by_id    :bigint
#  registration_id      :bigint           not null
#
# Indexes
#
#  index_scores_on_code                (code) UNIQUE
#  index_scores_on_first_input_by_id   (first_input_by_id)
#  index_scores_on_last_edited_by_id   (last_edited_by_id)
#  index_scores_on_registration_id     (registration_id) UNIQUE
#  index_scores_on_result_report_slug  (result_report_slug) UNIQUE
#  index_scores_on_slug                (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (first_input_by_id => users.id)
#  fk_rails_...  (last_edited_by_id => users.id)
#  fk_rails_...  (registration_id => registrations.id)
#
require "nanoid"
class Score < ApplicationRecord
  include ResultDocUploader::Attachment(:result_doc)
  include ResultReportUploader::Attachment(:result_report)

  belongs_to :registration
  belongs_to :first_input_by, class_name: 'User', optional: true
  belongs_to :last_edited_by, class_name: 'User', optional: true

  before_save :set_code_slug, if: :new_record?

  enum doc_status: { processing: 0, completed: 1, error: 2 }, _prefix: :doc
  enum result_report_status: { idle: 0, processing: 1, completed: 2, error: 3 }, _prefix: :result


  def is_scored?
    score_grade.nil?
  end

  private
  def set_code_slug
    custom_alphabet = ('A'..'Z').to_a.join + ('1'..'9').to_a.join
    self.code = Nanoid.generate(size: 7, alphabet: custom_alphabet)
    self.slug = Nanoid.generate(size: 8)
  end
end
