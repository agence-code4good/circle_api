# app/services/validations/forbidden_value_if_casket_validation.rb
require_relative "base_validation"

module Validations
  class ForbiddenValueIfCasketValidation < BaseValidation
    def validate
      # N'applique la validation que si on est en mode coffret
      return nil unless casket_mode?

      forbidden = rule["forbidden_values"] || []
      values = value.is_a?(Array) ? value : [ value ]

      violating = values.select { |v| forbidden.include?(v) }
      unless violating.empty?
        return "En mode coffret, #{code} ne peut pas contenir les valeurs #{forbidden.join(', ')} (valeurs trouvées : #{violating.join(', ')})."
      end

      nil
    end

    def default_error_message(code)
      "Erreur de forbidden_value_if_casket sur #{code}."
    end
  end
end
