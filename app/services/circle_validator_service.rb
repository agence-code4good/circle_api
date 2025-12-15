# app/services/circle_validator_service.rb
require "json"

class CircleValidatorService
  attr_reader :circle_values, :config, :errors, :version

  VALIDATION_CLASSES = {
    "single_value"            => Validations::SingleValueValidation,
    "forbidden_value"         => Validations::ForbiddenValueValidation,
    "excluded_combinations"   => Validations::ExcludedCombinationsValidation,
    "casket_value"            => Validations::CasketValueValidation,
    "dependency"              => Validations::DependencyValidation,
    "match_value"             => Validations::MatchValueValidation,
    "duplicate_value"         => Validations::DuplicateValueValidation,
    "numeric_value"           => Validations::NumericValueValidation,
    "in_database"             => Validations::InDatabaseValidation,
    "in_database_combination" => Validations::InDatabaseCombinationValidation,
    "product_validation"      => Validations::ProductValidation
  }

  CONFIG_JSON = File.read(Rails.root.join("specs", "circle_validation_rules.json"))

  def initialize(circle_values, config_json = CONFIG_JSON)
    @circle_values = circle_values
    @config = JSON.parse(config_json)
    @errors = {}
  end

  def validate
    @config.each do |code, settings|
      value = @circle_values[code]
      # Valeur par défaut quand aucune valeur n'est fournie ("00" ou array de "00" si coffret)
      if value.nil?
        if needs_casket_default_array?(settings)
          c2_value = @circle_values["C2"]
          length = c2_value.is_a?(Array) ? c2_value.first.to_i : c2_value.to_i
          value = Array.new(length, "00")
          @circle_values[code] = value
        else
          value = "00"
          @circle_values[code] = "00"
        end
      end
      settings["validations"].each do |rule|
        validation_class = VALIDATION_CLASSES[rule["type"]]
          next if validation_class.nil?
        validator = validation_class.new(code, value, rule, version, circle_values)
        error = validator.validate
        if error
          @errors[code] ||= []
            if error.is_a?(Array)
              @errors[code].concat(error)
            else
              @errors[code] << error
            end
        end
      end
    end
    @errors
  end

  private

  def needs_casket_default_array?(settings)
    settings["validations"].any? { |rule| rule["type"] == "casket_value" && rule["match_c2_length"] }
  end
end
