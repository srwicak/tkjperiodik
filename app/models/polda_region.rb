# == Schema Information
#
# Table name: polda_regions
#
#  id         :bigint           not null, primary key
#  name       :string
#  slug       :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_polda_regions_on_name  (name) UNIQUE
#  index_polda_regions_on_slug  (slug) UNIQUE
#
class PoldaRegion < ApplicationRecord
  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  has_many :polda_staffs, dependent: :destroy
  has_many :polda_reports, dependent: :destroy

  before_validation :set_slug

  private

  def set_slug
    self.slug ||= name.to_s.parameterize if name.present?
  end
end
