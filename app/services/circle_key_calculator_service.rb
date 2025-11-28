# app/services/circle_validator_service.rb
require "json"

class CircleKeyCalculatorService
  attr_reader :circle_values, :errors

  def initialize(circle_values)
    @circle_values = circle_values
    @errors = {}
  end

  def calculate
    values_for_calculation = []
    @circle_values.each do |code, value|
      next unless for_calculation?(code)
      values_for_calculation << value
    end
    calculate_key(values_for_calculation)
  end

  private

  def for_calculation?(code)
    code_str = code.to_s
    return false unless code_str.start_with?("C")

    last_char = code_str[-1]
    last_char.match?(/\d/)
  end

  def calculate_key(values_for_calculation)
    flattened_codes = values_for_calculation.flatten.join.upcase.chars

    values_sum = flattened_codes.sum do |value|
      value.match?(/[A-Z]/) ? (value.ord - "A".ord) + 1 : value.to_i
    end

    modulo = values_sum % 100
    modulo.to_s.rjust(3, "0")
  end
end
