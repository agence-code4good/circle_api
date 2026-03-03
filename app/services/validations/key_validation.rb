# app/services/validations/key_validation.rb
require_relative "base_validation"

module Validations
  class KeyValidation < BaseValidation
    def validate
      # Calculer la clé attendue
      calculator = CircleKeyCalculatorService.new(circle_values)
      expected_key = calculator.calculate

      # Comparer avec la valeur fournie
      if value != expected_key
        return "La clé CLE fournie (#{value}) n'est pas valide."
      end

      nil
    end

    def default_error_message(code)
      "Erreur de validation de la clé sur #{code}."
    end
  end
end
