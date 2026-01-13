# app/services/validations/match_pattern_validation.rb
require_relative "base_validation"

module Validations
  class MatchPatternValidation < BaseValidation
    # Dictionnaire de patterns réutilisables avec leurs messages d'erreur
    COMMON_PATTERNS = {
      "date_yyyymmdd" => {
        pattern: "^(19|20)\\d{2}(0[1-9]|1[0-2])(0[1-9]|[12]\\d|3[01])$",
        error_message: "doit être une date valide au format AAAAMMJJ (ex: 20160915)"
      },
      "year_yyyy" => {
        pattern: "^\\d{4}$",
        error_message: "doit être une année valide au format AAAA (ex: 2018)"
      },
      "numeric" => {
        pattern: "^\\d+$",
        error_message: "doit être un nombre entier positif"
      },
      "url_https" => {
        pattern: "^https://.*",
        error_message: "doit être une URL commençant par 'https://'"
      }
    }.freeze

    def validate
      pattern_config = get_pattern_config
      pattern = pattern_config[:pattern]
      error_template = pattern_config[:error_message]

      regex = Regexp.new(pattern)
      values = value.is_a?(Array) ? value : [value]
      
      values.each do |v|
        unless v =~ regex || v == "00"
          return "Le champ #{code} #{error_template}, valeur reçue : '#{v}'."
        end
      end
      nil
    end

    def default_error_message(code)
      "Erreur de match_pattern sur #{code}."
    end

    private

    def get_pattern_config
      # Support pour pattern_name (référence à un pattern prédéfini)
      if rule["pattern_name"]
        pattern_name = rule["pattern_name"]
        config = COMMON_PATTERNS[pattern_name]
        
        unless config
          raise "Pattern inconnu : '#{pattern_name}'. Patterns disponibles : #{COMMON_PATTERNS.keys.join(', ')}"
        end
        
        return config
      end

      # Support pour pattern (regex directe)
      if rule["pattern"]
        return {
          pattern: rule["pattern"],
          error_message: rule["error_message"] || "doit correspondre au format attendu"
        }
      end

      raise "Vous devez spécifier 'pattern' ou 'pattern_name' dans la règle de validation"
    end
  end
end
