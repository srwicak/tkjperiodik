# == Schema Information
#
# Table name: exams
#
#  id                        :bigint           not null, primary key
#  allow_onspot_registration :boolean          default(FALSE), not null
#  descriptions              :text
#  exam_date_end             :date
#  exam_date_start           :date
#  form_a_event_position     :string
#  form_a_name               :string
#  form_a_nrp                :string
#  form_a_police_position    :string
#  form_a_rank               :string
#  form_b_event_position     :string
#  form_b_name               :string
#  form_b_nrp                :string
#  form_b_police_position    :string
#  form_b_rank               :string
#  name                      :string           not null
#  notes                     :text
#  short_name                :string
#  size                      :integer          not null
#  slug                      :string           not null
#  start_register            :date
#  status                    :integer          default("draft"), not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#  created_by_id             :bigint
#  updated_by_id             :bigint
#
# Indexes
#
#  index_exams_on_created_by_id  (created_by_id)
#  index_exams_on_slug           (slug) UNIQUE
#  index_exams_on_updated_by_id  (updated_by_id)
#
# Foreign Keys
#
#  fk_rails_...  (created_by_id => users.id)
#  fk_rails_...  (updated_by_id => users.id)
#

require "nanoid"

class Exam < ApplicationRecord
  belongs_to :created_by, class_name: "User", foreign_key: "created_by_id", optional: true
  belongs_to :updated_by, class_name: "User", foreign_key: "updated_by_id", optional: true

  # 2025 Update - New Scheduling System
  has_many :exam_schedules, dependent: :destroy
  has_many :exam_sessions, dependent: :destroy
  has_many :registrations, through: :exam_sessions
  has_one :result_doc, dependent: :destroy

  # 2025 Update
  has_many :excel_uploads, dependent: :destroy

  enum status: {
    draft: 0,
    active: 1,
    archieve: 2,
  }

  before_save :set_slug
  after_create :create_result_doc

  def active?
    status == "active" && Date.current >= start_register
  end

  def create_result_doc
    if result_doc.nil?
      ResultDoc.create(exam: self)
    end
  end

  def can_register?
    active? && Date.current.between?(start_register, registration_end_time)
  end

  # def should_regenerate_sessions?
  #   saved_change_to_batch? || saved_change_to_exam_duration? || saved_change_to_break_time? || saved_change_to_exam_start? || saved_change_to_exam_date?
  # end

  def registration_end_time
    end_register + 1.day
  end

  def registration_open?
    Date.current.between?(start_register, registration_end_time)
  end

  def status_label
    I18n.t("exam.statuses.#{status}", default: status)
  end

  # 2025 Update: Check if exam has schedules
  def has_schedules?
    exam_schedules.exists?
  end

  # Get all available schedule dates
  def available_schedule_dates
    exam_schedules.where("exam_date >= ?", Date.tomorrow).order(:exam_date).pluck(:exam_date)
  end

  def registered_count
    registrations.count
  end

  # Check if on-spot registration is allowed and exam is today
  def allow_onspot_registration?
    allow_onspot_registration && active? && exam_today?
  end

  # Check if exam has any schedule today
  def exam_today?
    if has_schedules?
      exam_schedules.where(exam_date: Date.current).exists?
    else
      exam_date_start == Date.current || 
        (exam_date_start.present? && exam_date_end.present? && 
         Date.current.between?(exam_date_start, exam_date_end))
    end
  end

  # Get today's available sessions for on-spot registration
  def todays_available_sessions
    return ExamSession.none unless exam_today?
    
    today_schedules = exam_schedules.where(exam_date: Date.current)
    exam_sessions
      .joins(:exam_schedule)
      .where(exam_schedule: today_schedules)
      .where("size < max_size")
      .order(:start_time)
  end

  private

  # def register_dates_cannot_be_equal
  #   if start_register == end_register
  #     errors.add(:end_register, "Tanggal akhir daftar tidak bisa sama dengan Tanggal akhirnya")
  #   end
  # end

  # def adjust_end_register
  #   if start_register == end_register
  #     self.end_register = start_register + 1.day
  #   end
  # end

  def set_slug
    self.slug = Nanoid.generate(size: 6) if slug.blank?
  end
end
