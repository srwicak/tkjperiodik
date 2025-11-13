# == Schema Information
#
# Table name: exam_schedules
#
#  id               :bigint           not null, primary key
#  exam_date        :date             not null
#  max_participants :integer
#  notes            :text
#  schedule_name    :string
#  slug             :string
#  units            :integer          default([]), is an Array
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  exam_id          :bigint           not null
#
# Indexes
#
#  index_exam_schedules_on_exam_id             (exam_id)
#  index_exam_schedules_on_exam_id_and_exam_date  (exam_id,exam_date)
#  index_exam_schedules_on_slug                (slug) UNIQUE
#  index_exam_schedules_on_units               (units) USING gin
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
  validate :exam_date_must_be_future, on: :create
  validate :units_must_be_valid

  before_save :set_slug, if: :new_record?
  after_create :generate_exam_session

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
    registrations.count >= max_participants
  end

  # Hitung jumlah peserta terdaftar
  def registered_count
    registrations.count
  end

  # Check apakah unit tertentu bisa ujian di jadwal ini
  def available_for_unit?(unit_value)
    units.include?(unit_value)
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

  def units_must_be_valid
    if units.blank? || units.empty?
      errors.add(:units, "harus dipilih minimal satu satuan")
    end
  end

  # Generate satu exam session untuk jadwal ini
  def generate_exam_session
    start_time = Time.zone.parse("#{exam_date} #{exam.exam_start}")
    end_time = start_time + exam.exam_duration.minutes

    exam_sessions.create!(
      exam_id: exam.id,
      start_time: start_time,
      end_time: end_time,
      max_size: max_participants || 999999
    )
  end
end
