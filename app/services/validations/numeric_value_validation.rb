# app/services/validations/numeric_value_validation.rb
require_relative "base_validation"

module Validations
  class NumericValueValidation < BaseValidation
    def validate
      if casket_mode? && casket_allowed?
        return error_array_required unless value.is_a?(Array)

        invalids = value.reject { |v| integer?(v) }
        return error_invalid_list(invalids) if invalids.any?
      else
        return default_error_message(code) if value.is_a?(Array) || !integer?(value)
      end

      nil
    end

    def default_error_message(code)
      "Le champ #{code} doit être un nombre entier."
    end

    private

    def casket_allowed?
      rule.is_a?(Hash) && rule["casket_allowed"] == true
    end

    def integer?(raw)
      probe = Struct.new(:val) { include ActiveModel::Validations }.new(raw)
      ActiveModel::Validations::NumericalityValidator
        .new(attributes: [:val], only_integer: true)
        .validate(probe)
      probe.errors.empty?
    end

    def error_array_required
      "Le champ #{code} doit être un tableau de nombres entiers."
    end

    def error_invalid_list(invalids)
      "Le champ #{code} doit contenir uniquement des nombres entiers (invalides : #{invalids.map(&:inspect).join(', ')})"
    end
  end
end
