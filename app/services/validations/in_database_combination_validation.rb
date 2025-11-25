# app/services/validations/in_database_combination_validation.rb
require_relative "base_validation"

module Validations
  class InDatabaseCombinationValidation < BaseValidation
    def validate
      return nil if @circle_values.is_a?(String) && @circle_values == "00"

      combination_codes = rule["combination_codes"] || []
      mode = rule["combinaison_mode"] || "combined_codes"  # Par défaut, "combined_codes"

      case mode
      when "combined_codes"
        # On attend que la valeur soit un array dont chaque élément est un array (d'ensembles)
        unless value.is_a?(Array)
          return "La valeur de #{code} doit être un array (mode combined_codes)."
        end

        value.each do |combination_item|
          unless combination_item.is_a?(Array)
            return "Chaque élément de #{code} doit être un array (mode combined_codes). Reçu: #{combination_item.inspect}"
          end
          # Chaque combinaison_item est un ensemble (ou un array d'ensembles)
          # Si l'élément contient lui-même des arrays, on itère sur chacun d'eux
          if combination_item.any? && combination_item.first.is_a?(Array)
            combination_item.each do |ensemble|
              err = check_ensemble(ensemble, combination_codes)
              return err if err
            end
          else
            # Sinon, combination_item est directement un ensemble
            err = check_ensemble(combination_item, combination_codes)
            return err if err
          end
        end

      when "single_code"
        # On attend que la valeur soit un array plat de taille exactement égale à combination_codes.size
        unless value.is_a?(Array) && value.size == combination_codes.size
          return "La valeur de #{code} doit être un array de taille #{combination_codes.size} (mode single_code). Reçu: #{value.inspect}"
        end

        value.each_with_index do |element, idx|
          current_code = combination_codes[idx]
          if element.is_a?(Array)
            element.each do |single_val|
              unless in_database?(current_code, single_val)
                return "La valeur '#{single_val}' pour le code #{current_code} n'existe pas en base."
              end
            end
          else
            unless in_database?(current_code, element)
              return "La valeur '#{element}' pour le code #{current_code} n'existe pas en base."
            end
          end
        end

      else
        return "Mode de combinaison inconnu pour #{code}."
      end

      nil
    end

    def default_error_message(code)
      "Erreur in_database_combination sur #{code}."
    end

    private

    # Vérifie qu'un ensemble (array) a la taille attendue et que chaque valeur existe en base.
    def check_ensemble(ensemble, combination_codes)
      unless ensemble.is_a?(Array) && ensemble.size == combination_codes.size
        return "Un ensemble dans #{code} doit être un array de taille #{combination_codes.size} (reçu : #{ensemble.inspect})."
      end

      combination_codes.each_with_index do |cc, idx|
        val = ensemble[idx]
        unless in_database?(cc, val)
          return "La valeur '#{val}' pour le code #{cc} n'existe pas en base."
        end
      end

      nil
    end

    # Vérifie qu'une valeur existe en base pour le code donné, dans la version correspondante.
    def in_database?(circle_code, val)
      allowed_values = allowed_values(circle_code)
      allowed_values.include?(val)
    end
  end
end
