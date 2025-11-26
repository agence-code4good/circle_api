class OrderLine < ApplicationRecord
  belongs_to :order

  validates :circle_code, presence: true
  validate :is_valid

  def total_volume
    circle_code["C2"].to_i
  end

  def is_valid
    return if circle_code.nil?

    validation_errors = CircleValidatorService.new(circle_code).validate

    if validation_errors.any?
      # Ajouter les erreurs au format lisible
      validation_errors.each do |code, errors_array|
        errors.add(:circle_code, "#{code}: #{errors_array.join(', ')}")
      end
    end
  end
end
