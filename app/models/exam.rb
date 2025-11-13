# == Schema Information
#
# Table name: exams
#
#  id              :bigint           not null, primary key
#  batch           :integer          not null
#  break_time      :integer          not null
#  descriptions    :text
#  exam_date_end   :date
#  exam_date_start :date
#  exam_duration   :integer          not null
#  exam_rest_end   :time
#  exam_rest_start :time
#  exam_start      :time             not null
#  name            :string           not null
#  notes           :text
#  short_name      :string
#  size            :integer          not null
#  slug            :string           not null
#  start_register  :date
#  status          :integer          default("draft"), not null
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  created_by_id   :bigint
#  updated_by_id   :bigint
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

  # validate :register_dates_cannot_be_equal

  validate :check_and_handle_registrations, on: :update


  before_save :set_slug
  # before_save :adjust_end_register

  after_create :generate_sessions
  after_create :create_result_doc

  # before_update :ensure_no_registrations_on_update, if: :should_regenerate_sessions?

  # before_destroy :ensure_no_registrations_on_delete

  # after_save :regenerate_sessions, if: :should_regenerate_sessions?

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

  # def ensure_no_registrations_on_update
  #   puts "YOOOOOOOO========================================HOY"
  #   if exam_sessions.joins(:registrations).exists?
  #     puts "============================================HOY"
  #     errors.add(:base, "Tidak bisa mengubah jadwal dan total peserta ketika ujian yang telah ada pendaftarnya")
  #     throw(:abort)
  #   end
  # end

  # def ensure_no_registrations_on_delete
  #   puts "=======================================DELETE"
  #   registration_exists = exam_sessions.joins(:registrations).exists?
  #   puts "Registration exists? #{registration_exists}"
  #   if registration_exists
  #     puts "GABISAAPUS"
  #     errors.add(:base, "Tidak bisa menghapus ujian yang telah ada pendaftarnya")
  #     throw(:abort)
  #   else
  #     puts "BISA DIHAPUS"
  #   end
  # end

  def regenerate_sessions
    exam_sessions.destroy_all
    generate_sessions
  end

  # # single day generate
  # def generate_sessions
  #   current_start = exam_start
  #   batch.times do |i|
  #     start_time = Time.zone.parse("#{exam_date} #{current_start}")
  #     end_time = start_time + exam_duration.minutes
  #     exam_sessions.create!(
  #       start_time: start_time,
  #       end_time: end_time,
  #       max_size: size,
  #     )
  #     current_start = (start_time + exam_duration.minutes + break_time.minutes).strftime("%H:%M")
  #   end
  # end

  # multi day generate
  def generate_sessions
    current_date = exam_date_start

    while current_date <= exam_date_end
      # Skip weekends
      unless current_date.saturday? || current_date.sunday?
        current_start = exam_start

        batch.times do |i|
          start_time = Time.zone.parse("#{current_date} #{current_start}")
          end_time = start_time + exam_duration.minutes

          # Handle rest period
          if start_time >= Time.zone.parse("#{current_date} #{exam_rest_start}") && start_time < Time.zone.parse("#{current_date} #{exam_rest_end}")
            start_time = Time.zone.parse("#{current_date} #{exam_rest_end}")
            end_time = start_time + exam_duration.minutes
          elsif end_time > Time.zone.parse("#{current_date} #{exam_rest_start}") && end_time <= Time.zone.parse("#{current_date} #{exam_rest_end}")
            end_time = Time.zone.parse("#{current_date} #{exam_rest_end}") + exam_duration.minutes
          end

          exam_sessions.create!(
            start_time: start_time,
            end_time: end_time,
            max_size: size,
          )

          current_start = (end_time + break_time.minutes).strftime("%H:%M")
        end
      end

      # Move to the next day
      current_date += 1.day
    end
  end

  def registered_count
    registrations.count
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

  def check_and_handle_registrations
    if registrations.exists?
      if start_register_changed? || exam_date_start_changed? || exam_date_end_changed? || exam_duration_changed? || batch_changed? || size_changed? || break_time_changed?
        errors.add(:base, "Tidak dapat mengubah tanggal mulai dan berakhir ujian, durasi, batch, ukuran, atau waktu istirahat jika ada pendaftar.")
      end
    else
      regenerate_sessions
    end
  end
end
