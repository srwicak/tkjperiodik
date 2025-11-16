# == Schema Information
#
# Table name: users
#
#  id                     :bigint           not null, primary key
#  account_status         :integer          default("pending"), not null
#  account_status_reason  :string
#  consumed_timestep      :integer
#  current_sign_in_at     :datetime
#  current_sign_in_ip     :string
#  email                  :string           default(""), not null
#  encrypted_password     :string           default(""), not null
#  failed_attempts        :integer          default(0), not null
#  forgotten_at           :datetime
#  forgotten_count        :integer          default(0)
#  identity               :string           not null
#  is_forgotten           :boolean          default(FALSE)
#  is_onboarded           :boolean          default(FALSE)
#  is_verified            :boolean          default(FALSE)
#  last_sign_in_at        :datetime
#  last_sign_in_ip        :string
#  locked_at              :datetime
#  otp_required_for_login :boolean
#  otp_secret             :string
#  remember_created_at    :datetime
#  reset_password_sent_at :datetime
#  reset_password_token   :string
#  sign_in_count          :integer          default(0), not null
#  slug                   :string           not null
#  unlock_token           :string
#  created_at             :datetime         not null
#  updated_at             :datetime         not null
#
# Indexes
#
#  index_users_on_account_status        (account_status)
#  index_users_on_identity              (identity) UNIQUE
#  index_users_on_reset_password_token  (reset_password_token) UNIQUE
#  index_users_on_slug                  (slug) UNIQUE
#  index_users_on_unlock_token          (unlock_token) UNIQUE
#
require "nanoid"

class User < ApplicationRecord
  before_save :set_slug, if: :new_record?

  has_one :user_detail, dependent: :destroy
  has_many :registration, dependent: :destroy

  devise :two_factor_authenticatable
  devise :registerable,
         :rememberable, :validatable, :trackable,
         :timeoutable, :lockable,
         authentication_keys: [:identity]

  encrypts :identity, :email, deterministic: true
  #encrypts :email, deterministic: true

  attr_accessor :password_strength

  validate :identity_length_must_be_valid
  validates :identity, presence: true, uniqueness: true

  validate :password_complexity
  validates :password, presence: true, on: :create
  validates :password, confirmation: true, if: :password_present?

  validate :unique_email_excluding_blank
  validates :email, uniqueness: true, allow_blank: true

  accepts_nested_attributes_for :user_detail

  # pending like not yet checked by operator
  # blocked like do harmful things
  enum account_status: {
    active: 0,    # Aktif
    pending: 1,   # Menunggu
    rejected: 2,  # Ditolak
    suspended: 3, # Ditangguhkan
    blocked: 4,    # Diblokir
  }

  ACCOUNT_STATUS_MAPPING = {
    active: "Aktif",
    pending: "Menunggu",
    rejected: "Ditolak",
    suspended: "Ditangguhkan",
    blocked: "Diblokir",
  }

  def formatted_account_status
    ACCOUNT_STATUS_MAPPING[account_status.to_sym]
  end

  # Disable email validation from Devise
  def email_required?
    false
  end

  def email_changed?
    false
  end

  def will_save_change_to_email?
    false
  end

  def unique_email_excluding_blank
    if email.present? && User.where.not(id: id).exists?(email: email)
      errors.add(:email, "telah digunakan. Masukkan email lain.")
    end
  end

  def is_police?
    identity.length == 8
  end

  def is_staff?
    identity.length == 18
  end

  # Check if the length of the identity is either 8 or 18, and add an error if it's not.
  def identity_length_must_be_valid
    unless [8, 18].include?(identity&.length)
      errors.add(:identity, :invalid_length)
    end
  end

  # Add custom lock strategy
  def lock_access!(opts = {})
    self.locked_at = Time.now.utc
    save(validate: false)
  end

  def unlock_access!
    self.failed_attempts = 0
    self.locked_at = nil
    save(validate: false)
  end

  def self.human_attribute_name(attr, options = {})
    case attr.to_s
    when "identity"
      "NRP/NIP"
    when "password"
      "Kata Sandi"
    when "password_confirmation"
      "Konfirmasi Kata Sandi"
    else
      super
    end
  end

  def password_present?
    password.present?
  end

  def password_complexity
    return unless password.present?
    unless password.length >= 8 && password.match?(/\A(?=.*[a-zA-Z])(?=.*\d).+\z/)
      errors.add(:password, :too_weak)
    end
  end

  def password_required?
    # Validate the password only if the password is not empty or the user is new
    password.present? || new_record?
  end

  def admin?
    user_detail.is_superadmin_granted? || user_detail.is_operator_granted?
  end

  private

  def set_slug
    self.slug = Nanoid.generate(size: 6)
  end
end
