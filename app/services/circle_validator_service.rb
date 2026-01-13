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
    "match_pattern"           => Validations::MatchPatternValidation,
    "match_other_code_length" => Validations::MatchOtherCodeLengthValidation,
    "duplicate_value"         => Validations::DuplicateValueValidation,
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
        value = apply_default_value(code, settings)
      end
      validate_code_rules(code, value, settings["validations"])
    end
    @errors
  end

  private

  def validate_code_rules(code, value, rules)
    rules.each do |rule|
      error = validate_rule(code, value, rule)
      add_error(code, error) if error
    end
  end

  def validate_rule(code, value, rule)
    validation_class = validation_class_for(rule["type"])
    return nil if validation_class.nil?

    validator = validation_class.new(code, value, rule, version, circle_values)
    validator.validate
  end

  def validation_class_for(rule_type)
    VALIDATION_CLASSES[rule_type]
  end

  def add_error(code, error)
    @errors[code] ||= []
    if error.is_a?(Array)
      @errors[code].concat(error)
    else
      @errors[code] << error
    end
  end

  def apply_default_value(code, settings)
    default_value = calculate_default_value(settings)
    @circle_values[code] = default_value
  end

  def calculate_default_value(settings)
    return default_casket_array if needs_casket_default_array?(settings) && c2_is_array?
    "00"
  end

  def default_casket_array
    length = @circle_values["C2"].first.to_i
    Array.new(length, "00")
  end

  def c2_is_array?
    @circle_values["C2"].is_a?(Array)
  end

  def needs_casket_default_array?(settings)
    settings["validations"].any? { |rule| rule["type"] == "casket_value" && rule["match_c2_length"] }
  end
end
