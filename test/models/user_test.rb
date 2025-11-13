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
require "test_helper"

class UserTest < ActiveSupport::TestCase
  # test "the truth" do
  #   assert true
  # end
end
