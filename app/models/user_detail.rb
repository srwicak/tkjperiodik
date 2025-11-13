# == Schema Information
#
# Table name: user_details
#
#  id                    :bigint           not null, primary key
#  date_of_birth         :date
#  gender                :boolean          not null
#  is_operator_granted   :boolean          default(FALSE), not null
#  is_superadmin_granted :boolean          default(FALSE), not null
#  name                  :string           default(""), not null
#  person_status         :integer          not null
#  position              :string
#  rank                  :integer
#  unit                  :integer
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#  user_id               :bigint
#
# Indexes
#
#  index_user_details_on_user_id  (user_id)
#
class UserDetail < ApplicationRecord
  belongs_to :user

  before_validation :set_person_status_based_on_identity

  encrypts :name

  include UserDetailEnums
  include UserDetailMappings

  validates :user, presence: true
  validates :name, presence: true, format: { with: /\A[a-zA-Z.,'\- ]+\z/, message: "hanya boleh berisi alfabet, titik, koma, apostrof, dan tanda hubung" }

  validates :gender, inclusion: { in: [true, false] }
  validates :rank, presence: true, if: -> { user.is_police? }
  validates :unit, presence: true, if: -> { user.is_police? }
  #validates :position, presence: true, if: -> { user.is_police? }

  private

  def set_person_status_based_on_identity
    return if user.identity.blank?

    case user.identity.length
    when 8
      self.person_status = :police
    when 18
      self.person_status = :staff
    # 2025 update
    when 10
      self.person_status = :polda_staff
    else
      errors.add(:identity, :invalid_length, message: "must be 8, 10, or 18 characters long")
      throw(:abort)
    end
  end
end
