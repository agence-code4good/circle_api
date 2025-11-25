# app/services/validations/base_validation.rb
module Validations
  class BaseValidation
    attr_reader :code, :value, :rule, :version, :circle_values

    def initialize(code, value, rule, version, circle_values)
      @code = code
      @value = value
      @rule = rule
      @version = version
      @circle_values = circle_values
    end

    def validate
      raise NotImplementedError, "Subclasses must implement validate"
    end

    def casket_mode?
      @circle_values["C2"].is_a?(Array)
    end

    def error_message(code)
      default_error_message(code)
    end

    # TO DO : this method has to be adapted depending on your own database scema
    def allowed_values(code)
      circle_code = @version.circle_codes.find_by(code: code)

      unless circle_code
        return error_message("value" => "Ce code Circle n'existe pas pour cette version")
      end

      circle_code.circle_characteristics.pluck(:circle_value)
    end

    # TO DO : this method has to be adapted depending on your own database scema
    def find_product
      @version.circle_codes.find_by(code: code).circle_characteristics.find_by(circle_value: value)&.characterizable
    end
    
    private
    
    def default_error_message(code)
      "Erreur sur #{code}"
    end
  end
end
