# == Schema Information
#
# Table name: registrations
#
#  id                :bigint           not null, primary key
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

  validate :assign_to_session, on: :create

  # 2025 Update
  # This version is more robust and handles various edge cases better.
  validates :user_id, uniqueness: { scope: :exam_session_id, message: "sudah terdaftar di sesi ini" }

  before_save :set_slug, if: :new_record?
  after_create :increment_session_size
  after_create :create_associated_score

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

  def create_associated_score
    self.create_score!
  end

  def set_slug
    self.slug = Nanoid.generate(size: 8) if slug.blank?
  end
end
