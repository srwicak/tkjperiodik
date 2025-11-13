# == Schema Information
#
# Table name: batches
#
#  id                :bigint           not null, primary key
#  batch_data        :text
#  processed_count   :integer          default(0)
#  registration_type :integer
#  slug              :string
#  status            :integer          default("processing")
#  total_count       :integer          default(0)
#  unit              :integer
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exam_id           :bigint           not null
#
# Indexes
#
#  index_batches_on_exam_id  (exam_id)
#  index_batches_on_slug     (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#
require "nanoid"
class Batch < ApplicationRecord
  include BatchUploader::Attachment(:batch)

  belongs_to :exam

  before_save :set_slug, if: :new_record?

  enum status: { processing: 0, completed: 1, error: 2 }

  def update_progress!(increment)
    self.processed_count += increment
    self.save!

    # Update status to completed if all documents are processed
    self.completed! if self.processed_count == self.total_count
  end

  def set_slug
    self.slug = Nanoid.generate(size: 8) if slug.blank?
  end
end
