class OrderLine < ApplicationRecord
  belongs_to :order

  validates :circle_code, presence: true
  validate :is_valid

  scope :from_order_reference, ->(order_reference) { where(order_id: Order.find_by(order_reference: order_reference).id) }

  def total_volume
    circle_code["C31"].to_i
  end

  def is_valid
    return if circle_code.nil?

    validation_errors = CircleValidatorService.new(circle_code).validate

    if validation_errors.any?
      # Ajouter les erreurs au format lisible
      validation_errors.each do |code, errors_array|
        errors.add(:circle_code, "#{code}: #{errors_array.join(', ')}")
      end
      return
    end

    circle_key = CircleKeyCalculatorService.new(circle_code).calculate
    if circle_key != circle_code["CLE"]
      errors.add(:circle_code, "La clé Circle n'est pas valide")
      nil
    end
  end

  ## Pour la création des order_lines via ActiveAdmin (entrée JSON)
  def circle_code_json
    circle_code.present? ? JSON.pretty_generate(circle_code) : ""
  end

  def circle_code_json=(value)
    return if value.blank?
    self.circle_code = JSON.parse(value)
  rescue JSON::ParserError
    errors.add(:circle_code, "n'est pas un JSON valide")
  end
end
