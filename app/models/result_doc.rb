# == Schema Information
#
# Table name: result_docs
#
#  id         :bigint           not null, primary key
#  content    :jsonb
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  exam_id    :bigint           not null
#
# Indexes
#
#  index_result_docs_on_exam_id  (exam_id)
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#
require "nanoid"
class ResultDoc < ApplicationRecord
  belongs_to :exam

  before_save :set_slug, if: :new_record?

  def set_slug
    self.slug = Nanoid.generate(size: 8) if slug.blank?
  end
end
