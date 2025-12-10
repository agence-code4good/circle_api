# app/services/validations/dependency_validation.rb
require_relative "base_validation"

module Validations
  class DependencyValidation < BaseValidation
    def validate
      source_code  = rule["source_code"]
      source_value = rule["source_value"]
      target_value = rule["target_value"]
      src_val = circle_values[source_code]
      src_values = src_val.is_a?(Array) ? src_val : [ src_val ]
      tgt_values = value.is_a?(Array) ? value : [ value ]
      if src_values.include?(source_value) && !tgt_values.include?(target_value)
        return "Si #{source_code} vaut '#{source_value}', alors #{code} doit être '#{target_value}' (valeur reçue : '#{value}')."
      end
      nil
    end

    def default_error_message(code)
      "Erreur de dependency sur #{code}."
    end
  end
end
