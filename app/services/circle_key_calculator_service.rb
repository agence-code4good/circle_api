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
    calculated_key = calculate_key(values_for_calculation)
    @errors
  end

  private

  def for_calculation?(code)
    code_str = code.to_s
    return false unless code_str.start_with?("C")

    last_char = code_str.last
    last_char.match?(/\d/)
  end

    def calculate_key(values_for_calculation)
      debugger
      values_for_calculation.flatten.join.map do |value|
        # convert letters to numbers (their position in the alphabet)
        value.match?(/[A-Z]/) ? value.ord + 1 : value.to_i
      end.sum % 100
    end
end
