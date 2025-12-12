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

  CONFIG_JSON = File.read(Rails.root.join("specs", "circle_validations.json"))

  def initialize(circle_values, config_json = CONFIG_JSON)
    @circle_values = parse_circle_values(circle_values)
    @config = JSON.parse(config_json)
    @errors = {}
  end

  def validate
    @config.each do |code, settings|
      value = @circle_values[code]
      @circle_values[code] = "00" && value = "00" if value.nil?  # Valeur par défaut à "00" (ND) si aucune valeur n'est fournie
      settings["validations"].each do |rule|
        validation_class = VALIDATION_CLASSES[rule["type"]]
        next if validation_class.nil?
        validator = validation_class.new(code, value, rule, version, circle_values)
        error = validator.validate
        if error
          @errors[code] ||= []
          @errors[code] << error
        end
      end
    end
    @errors
  end

  private

  def parse_circle_values(values)
    return values unless values.is_a?(Hash)

    values.transform_values do |val|
      parse_json_value(val)
    end
  end

  def parse_json_value(val)
    return val unless val.is_a?(String)

    # Vérifier si c'est une string JSON valide (array ou object)
    stripped = val.strip
    return val unless (stripped.start_with?("[") && stripped.end_with?("]")) ||
                      (stripped.start_with?("{") && stripped.end_with?("}"))

    begin
      JSON.parse(val)
    rescue JSON::ParserError
      val
    end
  end
end
