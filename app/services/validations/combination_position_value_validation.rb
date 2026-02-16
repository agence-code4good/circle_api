# app/services/validations/combination_position_value_validation.rb
require_relative "base_validation"

module Validations
  class CombinationPositionValueValidation < BaseValidation
    def validate
      # Ne s'applique qu'aux arrays (combinaisons)
      return nil unless value.is_a?(Array)

      position_index = rule["position_index"]
      position_code = rule["position_code"]
      allowed_vals = rule["allowed_values"] || []

      # Vérifier que l'index est valide
      return nil if position_index.nil? || position_index >= value.length

      position_value = value[position_index]

      # Si c'est un array (ex: C5), vérifier chaque élément
      values_to_check = position_value.is_a?(Array) ? position_value : [ position_value ]

      values_to_check.each do |v|
        unless allowed_vals.include?(v)
          return "La valeur '#{v}' à la position #{position_index} (#{position_code}) n'est pas autorisée. Valeurs autorisées : #{allowed_vals.join(', ')}."
        end
      end

      nil
    end

    def default_error_message(code)
      "Erreur combination_position_value sur #{code}."
    end
  end
end
