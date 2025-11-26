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
      @products_csv ||= begin
        products = {}
        CSV.foreach(PRODUCTS_CSV_PATH, headers: true) do |row|
          c10 = row["C10"]
          next if c10.nil? || c10.strip.empty?

          products[c10] = Product.new(
            code: c10,
            label: row["Etiquette"] || c10,
            starting_vintage: row["Premier millésime"],
            late_vintage: row["Dernier Millésime"],
            excluded_vintages: row["Millésime(s) non produit(s)"]
          )
        end
        products
      end
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

    # TO DO : this method has to be adapted depending on your own database scema
    def find_product
      self.class.products_csv[value]
    end

    private

    def default_error_message(code)
      "Erreur sur #{code}"
    end
  end
end
