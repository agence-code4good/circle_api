# app/services/validations/excluded_combinations_validation.rb
require_relative "base_validation"

module Validations
  class ExcludedCombinationsValidation < BaseValidation
    def validate
      combinations = rule["excluded_combinations"] || []
      values = value.is_a?(Array) ? value : [value]

      combinations.each do |comb|
        matched_values = get_matched_values(comb, values)
        if matched_values
          return "La combinaison #{format_matched_values(matched_values)} n'est pas autorisée pour le code #{code}."
        end
      end
      nil
    end

    def default_error_message
      "Erreur d'excluded_combinations sur #{code}."
    end

    private

    def get_matched_values(combination, values)
      matched = []
      available_values = values.dup # Create a copy of values to track which ones are still available

      # Check if combination matches and collect matched values
      combination.each_with_index do |comb_element, index|
        found_match = false

        available_values.each_with_index do |val, val_index|
          if matches?(comb_element, val)
            matched[index] = val
            found_match = true
            # Remove the matched value from available values to prevent reusing it
            available_values.delete_at(val_index)
            break
          end
        end

        # If any element doesn't match, the whole combination doesn't match
        return nil unless found_match
      end

      matched
    end

    def matches?(pattern, value)
      if pattern.is_a?(String) && pattern.start_with?('/') && pattern.end_with?('/')
        # Handle regex pattern sent as string "/regex/" in json confi file
        regex_pattern = Regexp.new(pattern[1..-2])
        value.to_s.match?(regex_pattern)
      elsif pattern.is_a?(Regexp)
        value.to_s.match?(pattern)
      elsif pattern.is_a?(String)
        pattern == value
      end
    end

    def format_matched_values(matched_values)
      matched_values.join(' + ')
    end

    # Keep the old methods for backward compatibility
    def combination_match?(combination, values)
      !!get_matched_values(combination, values)
    end

    def format_combination(combination)
      combination.map do |element|
        if element.is_a?(String) && element.start_with?('/') && element.end_with?('/')
          element
        elsif element.is_a?(Regexp)
          element.inspect
        else
          element
        end
      end.join(' + ')
    end
  end
end
