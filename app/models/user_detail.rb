# == Schema Information
#
# Table name: user_details
#
#  id                    :bigint           not null, primary key
#  date_of_birth         :date
#  gender                :boolean          not null
#  is_operator_granted   :boolean          default(FALSE), not null
#  is_operator_active    :boolean          default(TRUE), not null
#  is_superadmin_granted :boolean          default(FALSE), not null
#  name                  :string           default(""), not null
#  person_status         :integer          not null
#  position              :string
#  rank                  :integer
#  unit                  :integer
#  work_schedule         :jsonb
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
  validates :name, presence: true, format: { with: /\A[a-zA-Z.,'\'\- ]+\z/, message: "hanya boleh berisi alfabet, titik, koma, apostrof, dan tanda hubung" }

  validates :gender, inclusion: { in: [true, false] }
  validates :rank, presence: true
  validates :unit, presence: true
  validates :position, presence: true

  # Check if operator is currently allowed to access based on status and schedule
  def operator_access_allowed?
    return false unless is_operator_granted
    return false unless is_operator_active
    
    # If no schedule is set, allow access anytime
    return true if work_schedule.blank? || work_schedule.empty?
    
    within_work_schedule?
  end

  # Check if current time is within work schedule
  def within_work_schedule?
    return true if work_schedule.blank? || work_schedule.empty?
    
    now = Time.current
    current_time = now.strftime("%H:%M")
    current_day = now.strftime("%A").downcase
    
    schedule = work_schedule[current_day]
    return false if schedule.blank?
    
    start_time = schedule["start"]
    end_time = schedule["end"]
    
    return false if start_time.blank? || end_time.blank?
    
    current_time >= start_time && current_time <= end_time
  end

  # Get work schedule status message
  def work_schedule_status
    return "Akses dinonaktifkan" unless is_operator_active
    return "Tidak ada jadwal (akses 24/7)" if work_schedule.blank? || work_schedule.empty?
    
    if within_work_schedule?
      "Dalam jam kerja"
    else
      "Di luar jam kerja"
    end
  end

  private

  def set_person_status_based_on_identity
    return if user.identity.blank?

    case user.identity.length
    when 8
      self.person_status = :police
    when 18
      self.person_status = :staff
    else
      errors.add(:identity, :invalid_length, message: "must be 8 or 18 characters long")
      throw(:abort)
    end
  end
end
