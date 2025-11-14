# == Schema Information
#
# Table name: exam_schedules
#
#  id               :bigint           not null, primary key
#  end_time         :time
#  exam_date        :date             not null
#  exam_date_end    :date
#  max_participants :integer
#  notes            :text
#  schedule_name    :string
#  slug             :string
#  start_time       :time
#  units            :integer          default([]), is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  exam_id          :bigint           not null
#
# Indexes
#
#  index_exam_schedules_on_exam_id                (exam_id)
#  index_exam_schedules_on_exam_id_and_exam_date  (exam_id,exam_date)
#  index_exam_schedules_on_slug                   (slug) UNIQUE
#  index_exam_schedules_on_units                  (units) USING gin
#
# Foreign Keys
#
#  fk_rails_...  (exam_id => exams.id)
#

require "nanoid"

class ExamSchedule < ApplicationRecord
  belongs_to :exam
  has_many :exam_sessions, dependent: :destroy
  has_many :registrations, through: :exam_sessions

  validates :exam_date, presence: true
  validates :units, presence: true
  validates :start_time, presence: true
  validates :end_time, presence: true
  
  validate :exam_date_must_be_future, on: :create
  validate :exam_date_end_must_be_valid
  validate :end_time_must_be_after_start_time
  validate :units_must_be_valid
  validate :cannot_update_dates_if_registrations_exist, on: :update

  before_save :set_slug, if: :new_record?
  after_create :generate_exam_sessions
  before_update :regenerate_sessions_if_dates_changed

  # Getter untuk units yang lebih mudah dibaca
  def unit_names
    return [] if units.blank?
    units.map { |u| UserDetail.units.key(u) }.compact
  end

  # Getter untuk schedule name yang auto-generate jika kosong
  def display_name
    schedule_name.presence || unit_names.join(", ")
  end

  # Check apakah jadwal sudah penuh
  def full?
    return false if max_participants.nil?
    registrations.count >= total_max_participants
  end

  # Hitung jumlah peserta terdaftar
  def registered_count
    registrations.count
  end

  # Hitung total kuota maksimal (kuota per hari × jumlah hari)
  def total_max_participants
    return nil if max_participants.nil?
    max_participants * total_days
  end

  # Check apakah unit tertentu bisa ujian di jadwal ini
  def available_for_unit?(unit_value)
    units.include?(unit_value)
  end
  
  # Helper untuk hitung durasi dalam jam
  def duration_hours
    return 0 if start_time.blank? || end_time.blank?
    ((Time.parse(end_time.to_s) - Time.parse(start_time.to_s)) / 3600).round(1)
  end
  
  # Helper untuk hitung jumlah hari (include all days)
  def total_days
    return 1 if exam_date_end.blank?
    end_date = exam_date_end
    (exam_date..end_date).count
  end

  private

  def set_slug
    self.slug = Nanoid.generate(size: 8) if slug.blank?
  end

  def exam_date_must_be_future
    if exam_date.present? && exam_date <= Date.today
      errors.add(:exam_date, "harus di masa depan")
    end
  end

  def exam_date_end_must_be_valid
    return if exam_date.blank? || exam_date_end.blank?
    if exam_date_end < exam_date
      errors.add(:exam_date_end, "tidak boleh lebih awal dari tanggal mulai")
    end
  end

  def end_time_must_be_after_start_time
    return if start_time.blank? || end_time.blank?
    if end_time <= start_time
      errors.add(:end_time, "harus lebih dari jam mulai")
    end
  end

  def units_must_be_valid
    if units.blank? || units.empty?
      errors.add(:units, "harus dipilih minimal satu satuan")
    end
  end

  def cannot_update_dates_if_registrations_exist
    return unless exam_date_changed? || exam_date_end_changed?
    
    if registrations.exists?
      errors.add(:base, "Tidak dapat mengubah tanggal karena sudah ada peserta yang terdaftar")
    end
  end

  def regenerate_sessions_if_dates_changed
    return unless exam_date_changed? || exam_date_end_changed? || start_time_changed? || end_time_changed?
    
    # Only regenerate if no registrations exist
    return if registrations.exists?
    
    # Delete existing sessions
    exam_sessions.destroy_all
    
    # Generate new sessions
    generate_exam_sessions
  end

  # Generate exam sessions untuk jadwal ini (support multi-hari, include weekends)
  def generate_exam_sessions
    end_date = exam_date_end.presence || exam_date
    current_date = exam_date

    while current_date <= end_date
      start_datetime = Time.zone.parse("#{current_date} #{start_time}")
      end_datetime = Time.zone.parse("#{current_date} #{end_time}")

      exam_sessions.create!(
        exam_id: exam.id,
        start_time: start_datetime,
        end_time: end_datetime,
        max_size: max_participants || 999999
      )

      current_date += 1.day
    end
  end
end
