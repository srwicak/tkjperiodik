# == Schema Information
#
# Table name: polda_reports
#
#  id              :bigint           not null, primary key
#  description     :text
#  file_data       :text
#  slug            :string           not null
#  title           :string           not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  exam_id         :bigint           not null
#  polda_region_id :bigint           not null
#  user_id         :bigint           not null
#
# Indexes
#
#  index_polda_reports_on_exam_id          (exam_id)
#  index_polda_reports_on_polda_region_id  (polda_region_id)
#  index_polda_reports_on_slug             (slug) UNIQUE
#  index_polda_reports_on_user_id          (user_id)
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#  fk_rails_...  (polda_region_id => polda_regions.id)
#  fk_rails_...  (user_id => users.id)
#
require "nanoid"
class PoldaReport < ApplicationRecord
  belongs_to :polda_region
  belongs_to :exam
  belongs_to :user

  encrypts :title, :description

  before_save :set_slug

  private

  def set_slug
    self.slug = Nanoid.generate(size: 6) if slug.blank?
  end
end
