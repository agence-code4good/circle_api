# app/services/validations/in_database_validation.rb
require_relative "base_validation"

module Validations
  class InDatabaseValidation < BaseValidation
    def validate
      allowed_values = allowed_values(code)

      values = value.is_a?(Array) ? value : [value]
      values.each do |v|
        unless allowed_values.include?(v)
          return "La valeur '#{v}' de #{code} n'existe pas en base."
        end
      end
      nil
    end

    def default_error_message(code)
      "Erreur in_database sur #{code}."
    end
  end
end
