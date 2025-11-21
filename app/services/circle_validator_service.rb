# app/services/validator_service.rb
# frozen_string_literal: true

class CircleValidatorService
  attr_reader :simulate_errors

  def initialize(circle_code, simulate_errors: false)
    @circle_code = circle_code
    @simulate_errors = simulate_errors
  end

  def call
    if simulate_errors
      { valid: false, errors: {
        "C4" => {
          "invalid_value" => "Valeur incorrecte pour le champ C4",
          "missing_field" => "Le champ C4 est obligatoire"
        },
        "C10" => {
          "unknown_reference" => "Le code C10 n'existe pas dans la base produits"
        }
      } }
    else
      { valid: true, errors: {} }
    end
  end
end
