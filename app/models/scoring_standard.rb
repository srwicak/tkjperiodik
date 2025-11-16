# == Schema Information
#
# Table name: scoring_standards
#
#  id            :bigint           not null, primary key
#  golongan      :integer          not null
#  jenis_kelamin :integer          not null
#  lookup_data   :jsonb            not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#
# Indexes
#
#  index_scoring_standards_on_golongan_and_jenis_kelamin  (golongan,jenis_kelamin) UNIQUE
#
class ScoringStandard < ApplicationRecord
  # Enums
  enum golongan: {
    golongan_1: 1,
    golongan_2: 2,
    golongan_3: 3,
    golongan_4: 4
  }
  
  enum jenis_kelamin: {
    pria: 0,
    wanita: 1
  }
  
  # Validations
  validates :golongan, presence: true, inclusion: { in: golongans.keys }
  validates :jenis_kelamin, presence: true, inclusion: { in: jenis_kelamins.keys }
  validates :lookup_data, presence: true
  validates :golongan, uniqueness: { scope: :jenis_kelamin }
  
  # Parse JSON string before validation
  before_validation :parse_lookup_data
  
  # Validate lookup_data structure
  validate :validate_lookup_data_structure
  
  # Get score for a specific test type and raw value
  # @param test_type [String] 'lari', 'pullup', 'chinning', 'situp', 'pushup', 'shuttlerun'
  # @param raw_value [Numeric] Raw value (e.g., 3444 for lari, 17 for pullup, 16.2 for shuttlerun)
  # @return [Integer, nil] Score (1-100) or nil if not found
  def get_score(test_type, raw_value)
    return nil unless lookup_data.present? && lookup_data[test_type].present?
    
    test_data = lookup_data[test_type]
    
    # For shuttlerun, raw_value is decimal (e.g., 16.2)
    # For others, raw_value is integer
    if test_type == 'shuttlerun'
      # Convert to string for lookup (e.g., "16.2")
      key = raw_value.to_s
      test_data[key]
    else
      # Direct lookup by value
      test_data[raw_value.to_s]
    end
  end
  
  # Find the closest score if exact match not found
  # Useful for interpolation or finding nearest value
  def get_closest_score(test_type, raw_value)
    return nil unless lookup_data.present? && lookup_data[test_type].present?
    
    test_data = lookup_data[test_type]
    return nil if test_data.empty?
    
    # Try exact match first
    exact_score = get_score(test_type, raw_value)
    return exact_score if exact_score.present?
    
    # Find closest value
    if test_type == 'shuttlerun'
      # For shuttlerun, lower time = better = higher score
      values = test_data.keys.map(&:to_f).sort
      closest = values.min_by { |v| (v - raw_value.to_f).abs }
      test_data[closest.to_s]
    else
      # For other tests, higher value = better = higher score
      values = test_data.keys.map(&:to_i).sort
      closest = values.min_by { |v| (v - raw_value.to_i).abs }
      test_data[closest.to_s]
    end
  end
  
  # Get all valid test types for this gender
  def valid_test_types
    if pria?
      ['lari', 'pullup', 'situp', 'pushup', 'shuttlerun']
    else
      ['lari', 'chinning', 'situp', 'pushup', 'shuttlerun']
    end
  end
  
  private
  
  def parse_lookup_data
    # If lookup_data is a String (JSON), parse it to Hash
    if lookup_data.is_a?(String)
      begin
        self.lookup_data = JSON.parse(lookup_data)
      rescue JSON::ParserError => e
        errors.add(:lookup_data, "format JSON tidak valid: #{e.message}")
      end
    end
  end
  
  def validate_lookup_data_structure
    return if lookup_data.blank?
    
    # Check if lookup_data has expected test types
    expected_types = valid_test_types
    
    expected_types.each do |test_type|
      unless lookup_data.key?(test_type)
        errors.add(:lookup_data, "harus memiliki data untuk #{test_type}")
      end
    end
    
    # Validate each test type has hash structure {raw_value => score}
    lookup_data.each do |test_type, data|
      unless data.is_a?(Hash)
        errors.add(:lookup_data, "data untuk #{test_type} harus berupa hash")
      end
    end
  end
end
