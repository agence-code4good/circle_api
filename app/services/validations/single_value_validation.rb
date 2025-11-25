# app/services/validations/single_value_validation.rb
require_relative "base_validation"

module Validations
  class SingleValueValidation < BaseValidation
    def validate
      unless casket_mode? || (!value.is_a?(Array) || value.size == 1)
        return error_message(code)
      end
      nil
    end

    def default_error_message(code)
      "Le champ #{code} doit contenir une seule valeur."
    end
  end
end
