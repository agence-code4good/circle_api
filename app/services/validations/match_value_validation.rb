# app/services/validations/match_value_validation.rb
require_relative "base_validation"

module Validations
  class MatchValueValidation < BaseValidation
    def validate
      pattern = rule["pattern"]
      regex = Regexp.new(pattern)
      values = value.is_a?(Array) ? value : [value]
      values.each do |v|
        unless v =~ regex || v == "00"
          return "L'URL de #{code} doit commencer par 'https://', valeur reçue : '#{v}'."
        end
      end
      nil
    end

    def default_error_message(code)
      "Erreur de match_value sur #{code}."
    end
  end
end
