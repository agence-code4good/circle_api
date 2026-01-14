# app/services/validations/in_database_validation.rb
require_relative "base_validation"

module Validations
  class InDatabaseValidation < BaseValidation
    def validate
      code_to_check = rule["filter_from_code"] || code
      allowed_values_list = allowed_values(code_to_check)
      # Si allowed_values retourne une erreur (string), on la retourne
      return allowed_values_list if allowed_values_list.is_a?(String)
      values = value.is_a?(Array) ? value : [ value ]
      values.each do |v|
        unless allowed_values_list.include?(v)
          return build_error_message(v, code_to_check)
        end
      end
      nil
    end

    def default_error_message(code)
      "Erreur in_database sur #{code}."
    end

    private

    def build_error_message(invalid_value, code_to_check)
      if rule["filter_from_code"]
        "La valeur '#{invalid_value}' de #{code} n'existe pas en base pour le code #{code_to_check}."
      else
        "La valeur '#{invalid_value}' de #{code} n'existe pas en base."
      end
    end
  end
end
