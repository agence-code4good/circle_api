# app/services/validations/combination_conditional_all_same_validation.rb
require_relative "base_validation"

module Validations
  class CombinationConditionalAllSameValidation < BaseValidation
    def validate
      # Ne s'applique qu'aux arrays (combinaisons)
      return nil unless value.is_a?(Array)

      trigger_position = rule["trigger_position"]
      trigger_code = rule["trigger_code"]
      trigger_value = rule["trigger_value"]
      required_value = rule["required_value"]

      # Vérifier que l'index est valide
      return nil if trigger_position.nil? || trigger_position >= value.length

      # Vérifier la valeur de déclenchement
      position_value = value[trigger_position]

      # Si position_value est un array, vérifier si trigger_value est dedans
      trigger_matched = if position_value.is_a?(Array)
        position_value.include?(trigger_value)
      else
        position_value == trigger_value
      end

      # Si la condition est déclenchée, vérifier toutes les valeurs
      if trigger_matched
        value.each_with_index do |val, idx|
          # Gérer les arrays (ex: C5, C20)
          values_to_check = val.is_a?(Array) ? val : [ val ]

          values_to_check.each do |v|
            unless v == required_value
              return "Si #{trigger_code} (position #{trigger_position}) est '#{trigger_value}', toutes les valeurs doivent être '#{required_value}'. Position #{idx} contient '#{v}'."
            end
          end
        end
      end

      nil
    end

    def default_error_message(code)
      "Erreur combination_conditional_all_same sur #{code}."
    end
  end
end
