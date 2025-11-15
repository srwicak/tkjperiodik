# == Schema Information
#
# Table name: registrations
#
#  id                :bigint           not null, primary key
#  golongan          :integer
#  is_attending      :boolean
#  pdf_data          :text
#  pdf_status        :integer
#  registration_type :integer
#  slug              :string
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  exam_session_id   :bigint           not null
#  user_id           :bigint           not null
#
# Indexes
#
#  index_registrations_on_exam_session_id              (exam_session_id)
#  index_registrations_on_slug                         (slug) UNIQUE
#  index_registrations_on_user_id                      (user_id)
#  index_registrations_on_user_id_and_exam_session_id  (user_id,exam_session_id) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (exam_session_id => exam_sessions.id)
#  fk_rails_...  (user_id => users.id)
#
require "nanoid"
class Registration < ApplicationRecord
  include PdfUploader::Attachment(:pdf)

  belongs_to :exam_session
  belongs_to :user

  has_one :score, dependent: :destroy

  # Commented out: Controller now handles session assignment based on user's selected date
  # validate :assign_to_session, on: :create

  # 2025 Update
  # This version is more robust and handles various edge cases better.
  validates :user_id, uniqueness: { scope: :exam_session_id, message: "sudah terdaftar di sesi ini" }

  before_save :set_slug, if: :new_record?
  after_create :increment_session_size
  after_create :create_associated_score
  after_destroy :decrement_session_size

  enum pdf_status: { processing: 0, completed: 1, error: 2 }

  enum registration_type: { berkala: 0, kenaikan_pangkat: 1 }

  # Helper untuk mendapatkan exam schedule
  def exam_schedule
    exam_session&.exam_schedule
  end

  # Helper untuk mendapatkan exam
  def exam
    exam_session&.exam
  end

  # Calculate age at exam date
  def age_at_exam
    return nil unless user&.user_detail&.date_of_birth && exam_schedule&.exam_date
    
    exam_date = exam_schedule.exam_date
    dob = user.user_detail.date_of_birth
    
    age = exam_date.year - dob.year
    age -= 1 if exam_date < dob + age.years
    age
  end

  # Calculate age with years, months, and days precision
  def age_in_years_and_days_at_exam
    return nil unless user&.user_detail&.date_of_birth && exam_schedule&.exam_date
    
    exam_date = exam_schedule.exam_date
    dob = user.user_detail.date_of_birth
    
    # Calculate years
    years = exam_date.year - dob.year
    years -= 1 if exam_date.month < dob.month || (exam_date.month == dob.month && exam_date.day < dob.day)
    
    # Calculate months
    months = exam_date.month - dob.month
    if months < 0
      months += 12
    elsif months == 0 && exam_date.day < dob.day
      months = 11
    end
    
    if exam_date.day < dob.day
      months -= 1 if months > 0
    end
    
    # Calculate days
    if exam_date.day >= dob.day
      days = exam_date.day - dob.day
    else
      # Get days in previous month
      prev_month = exam_date.prev_month
      days_in_prev_month = Date.new(prev_month.year, prev_month.month, -1).day
      days = days_in_prev_month - dob.day + exam_date.day
    end
    
    { years: years, months: months, days: days }
  end

  # Get age category based on exam date
  # 1: < 31 years (30 years 11 months 30 days still category 1)
  # 2: 31-40 years
  # 3: 41-50 years
  # 4: >= 51 years
  def age_category_at_exam
    age_data = age_in_years_and_days_at_exam
    return nil unless age_data
    
    years = age_data[:years]
    
    if years < 31
      '1'
    elsif years < 41
      '2'
    elsif years < 51
      '3'
    else
      '4'
    end
  end

  # DEPRECATED: Age calculation moved to client-side (JavaScript)
  # These class methods are kept for backward compatibility only
  # Use client-side JavaScript calculation in views instead
  
  # Helper method to calculate age for any user and date (class method)
  def self.calculate_age_at_date(date_of_birth, target_date)
    return nil unless date_of_birth && target_date
    
    # Calculate years
    years = target_date.year - date_of_birth.year
    years -= 1 if target_date.month < date_of_birth.month || (target_date.month == date_of_birth.month && target_date.day < date_of_birth.day)
    
    # Calculate months
    months = target_date.month - date_of_birth.month
    if months < 0
      months += 12
    elsif months == 0 && target_date.day < date_of_birth.day
      months = 11
    end
    
    if target_date.day < date_of_birth.day
      months -= 1 if months > 0
    end
    
    # Calculate days
    if target_date.day >= date_of_birth.day
      days = target_date.day - date_of_birth.day
    else
      # Get days in previous month
      prev_month = target_date.prev_month
      days_in_prev_month = Date.new(prev_month.year, prev_month.month, -1).day
      days = days_in_prev_month - date_of_birth.day + target_date.day
    end
    
    { years: years, months: months, days: days }
  end

  # Helper method to calculate category for any age (class method)
  def self.age_category(years)
    if years < 31
      '1'
    elsif years < 41
      '2'
    elsif years < 51
      '3'
    else
      '4'
    end
  end

  private

  def assign_to_session
    tomorrow_start = Time.zone.now.beginning_of_day + 1.day

    available_session = exam_session.exam.exam_sessions
      .where("size < max_size AND start_time >= ?", tomorrow_start)
      .order(:start_time)
      .find { |session| !session.full? }

    if available_session
      self.exam_session = available_session
    else
      errors.add(:base, "Mohon maaf semua sesi telah penuh.")
    end
  end

  def increment_session_size
    exam_session.increment!(:size)
  end

  def decrement_session_size
    exam_session.decrement!(:size)
  end

  def create_associated_score
    self.create_score!
  end

  def set_slug
    self.slug = Nanoid.generate(size: 8) if slug.blank?
  end
end
