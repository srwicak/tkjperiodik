# == Schema Information
#
# Table name: exam_sessions
#
#  id         :bigint           not null, primary key
#  end_time   :datetime         not null
#  max_size   :integer          not null
#  size       :integer          default(0), not null
#  slug       :string
#  start_time :datetime         not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  exam_id    :bigint           not null
#
# Indexes
#
#  index_exam_sessions_on_exam_id  (exam_id)
#  index_exam_sessions_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#

require "nanoid"

class ExamSession < ApplicationRecord
  belongs_to :exam
  has_many :registrations, dependent: :destroy

  validates :start_time, :end_time, :size, :max_size, presence: true

  before_save :set_slug, if: :new_record?

  def full?
    size >= max_size
  end

  def registration_count
    registrations.count
  end

  private

  def set_slug
    self.slug = Nanoid.generate(size: 6)
  end
end
