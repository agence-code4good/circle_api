# app/services/validations/forbidden_value_validation.rb
require_relative "base_validation"

module Validations
  class ForbiddenValueValidation < BaseValidation
    def validate
      forbidden = rule["forbidden_values"] || []
      values = value.is_a?(Array) ? value : [ value ]
      violating = values & forbidden
      unless violating.empty?
        return "La valeur '#{violating.join(', ')}' présente pour #{code} n'est pas autorisée."
      end
      nil
    end

    def default_error_message(code)
      "Erreur de forbidden_value sur #{code}."
    end
  end
end
