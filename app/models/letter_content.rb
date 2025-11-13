# == Schema Information
#
# Table name: letter_contents
#
#  id          :bigint           not null, primary key
#  name        :string
#  placeholder :json
#  slug        :string
#  created_at  :datetime         not null
#  updated_at  :datetime         not null
#  letter_id   :bigint           not null
#
# Indexes
#
#  index_letter_contents_on_letter_id  (letter_id)
#  index_letter_contents_on_slug       (slug) UNIQUE
#
# Foreign Keys
#
#  fk_rails_...  (letter_id => letters.id)
#
class LetterContent < ApplicationRecord
end
