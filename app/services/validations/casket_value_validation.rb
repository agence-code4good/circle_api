# app/services/validations/casket_value_validation.rb
require_relative "base_validation"

module Validations
  class CasketValueValidation < BaseValidation
    def validate
      return nil unless casket_mode?  

      if rule["match_array_length"]
        expected_length = circle_values["C2"].is_a?(Array) ? circle_values["C2"].first.to_i : 1
        actual_length = value.is_a?(Array) ? value.size : 0
        unless value.is_a?(Array)
          return "En coffret, #{code} doit être un tableau de #{expected_length} elements."
        end
        if actual_length != expected_length
          return "En coffret, #{code} doit être un tableau de #{expected_length} élément(s) (taille reçue : #{actual_length})."
        end
      else
        allowed = rule["allowed_values"] || []
        values = value.is_a?(Array) ? value : [value]
        violating = values.reject { |v| allowed.include?(v) }
        unless violating.empty?
          return "En coffret, #{code} doit être égal à #{allowed.join(', ')} (valeur reçue : '#{violating.join(', ')}')."
        end
      end
      nil
    end

    def default_error_message(code)
      "Erreur de casket_value sur #{code}."
    end
  end
end
