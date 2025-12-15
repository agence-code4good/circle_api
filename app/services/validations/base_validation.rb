# app/services/validations/base_validation.rb
require "yaml"
require "csv"
module Validations
  class BaseValidation
    attr_reader :code, :value, :rule, :version, :circle_values

    DICTIONARY_PATH = Rails.root.join("specs", "dictionnary.yml")
    PRODUCTS_CSV_PATH = Rails.root.join("specs", "products.csv")

    def self.dictionary
      @dictionary ||= YAML.load_file(DICTIONARY_PATH)
    end

    def self.parse_excluded_vintages(excluded_vintages_str)
      return [] if excluded_vintages_str.nil? || excluded_vintages_str.strip.empty? || excluded_vintages_str.strip == "ND"
      excluded_vintages_str.split(",").map(&:strip).reject(&:empty?)
    end

    def self.products_csv
      @products_csv ||= Product.all.index_by(&:code)
    end

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

    # Récupère les valeurs autorisées depuis le dictionnaire YAML
    def allowed_values(code)
      dictionary_entry = self.class.dictionary[code.to_s]

      unless dictionary_entry
        return error_message("value" => "Ce code Circle '#{code}' n'existe pas dans le dictionnaire")
      end

      # Si le code n'a pas d'enum, retourner un tableau vide
      enum = dictionary_entry["enum"]
      return [] unless enum.is_a?(Hash)

      # Retourner les clés de l'enum (les valeurs autorisées)
      enum.keys
    end

    def find_product
      if value.is_a?(Array)
        value.map { |v| self.class.products_csv[v] }
      else
        self.class.products_csv[value].to_a
      end
    end

    private

    def default_error_message(code)
      "Erreur sur #{code}"
    end
  end
end
