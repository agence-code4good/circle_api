class OrderLine < ApplicationRecord
  belongs_to :order

  validates :circle_code, presence: true
  validate :is_valid

  def total_volume
    circle_code["C2"].to_i
  end

  def is_valid
    result = CircleValidatorService.new(circle_code, simulate_errors: true).call
    errors.add(:base, result[:errors].to_json) unless result[:valid]
  end
end
