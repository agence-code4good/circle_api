# app/services/validations/duplicate_value_validation.rb
require_relative "base_validation"

module Validations
  class DuplicateValueValidation < BaseValidation
    def validate
      return nil unless value.is_a?(Array)
      if value.uniq.size != value.size
        return "#{code} ne doit pas contenir de doublons (valeurs : #{value.join(', ')})."
      end
      nil
    end

    def default_error_message(code)
      "Erreur de duplicate_value sur #{code}."
    end
  end
end
