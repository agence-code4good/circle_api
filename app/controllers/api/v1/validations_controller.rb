class Api::V1::ValidationsController < Api::BaseController
  before_action :authenticate_partner!

  def validate
    circle_values = validation_params[:circle_values]

    if circle_values.nil?
      render json: { error: "circle_values is required" }, status: :bad_request
      return
    end

    # Appeler directement le service de validation
    validation_errors = CircleValidatorService.new(circle_values).validate

    # Construire la réponse structurée
    circle_code_results = build_validation_results(circle_values, validation_errors)

    # Construire la réponse finale selon qu'il y a des erreurs ou non
    if validation_errors.empty?
      # Calculer la clé Circle si pas d'erreur
      circle_key = CircleKeyCalculatorService.new(circle_values).calculate
      render json: {
        circle_key: circle_key,
        circle_code: circle_code_results
      }, status: :ok
    else
      # Lister les codes en erreur si erreurs présentes
      error_codes = validation_errors.keys.sort
      render json: {
        errors: error_codes,
        circle_code: circle_code_results
      }, status: :ok
    end
  end

  private

  def validation_params
    params.permit(:version, circle_values: {})
  end

  def build_validation_results(circle_values, validation_errors)
    dictionary = Validations::BaseValidation.dictionary
    validation_rules = load_validation_rules
    results = []

    # Créer un index basé sur l'ordre des clés dans le dictionnaire YAML
    dictionary_order = dictionary.keys.each_with_index.to_h

    circle_values.each do |code, value|
      code_str = code.to_s
      dictionary_entry = dictionary[code_str]

      # Récupérer le label depuis le dictionnaire
      label = dictionary_entry&.dig("label") || code_str

      # Récupérer la valeur lisible selon le type de code
      enum_value = get_readable_value(code_str, value, dictionary, validation_rules)

      # Vérifier si ce code a des erreurs
      has_errors = validation_errors.key?(code_str)

      result = {
        circle_code: code_str,
        circle_value: value,
        label: label,
        value: enum_value,
        valid: !has_errors
      }

      # Ajouter les erreurs si présentes
      if has_errors
        result[:errors] = validation_errors[code_str]
      end

      results << result
    end

    # Trier les résultats selon l'ordre du dictionnaire YAML
    results.sort_by { |r| dictionary_order[r[:circle_code]] }
  end

  # Méthode récursive pour mapper les valeurs vers leurs labels depuis le dictionnaire (pour les champs C79 C80 notamment)
  def map_enum_value(value, dictionary_entry)
    if value.is_a?(Array)
      # Si c'est un array, mapper récursivement chaque élément
      value.map { |v| map_enum_value(v, dictionary_entry) }
    else
      # Si c'est une valeur simple, la mapper vers sa valeur dans le dictionnaire
      dictionary_entry&.dig("enum", value.to_s) || value.to_s
    end
  end

  # Pour C10 : mapper le(s) code(s) produit(s) vers leur label
  def map_product_label_value(value)
    if value.is_a?(Array)
      value.map { |v| product_label_for_code(v) }
    else
      product_label_for_code(value)
    end
  end

  def product_label_for_code(code)
    product = Validations::BaseValidation.products_csv[code.to_s]
    product&.label || code.to_s
  end

  # Charge les règles de validation depuis le JSON
  def load_validation_rules
    @validation_rules ||= JSON.parse(
      File.read(Rails.root.join("specs", "circle_validation_rules.json"))
    )
  end

  # Détermine quelle entry du dictionnaire utiliser pour mapper les valeurs
  def get_dictionary_entry_for_mapping(code_str, validation_rules, dictionary)
    # Vérifier si ce code a une validation in_database avec filter_from_code
    code_rules = validation_rules[code_str]

    if code_rules && code_rules["validations"]
      in_db_validation = code_rules["validations"].find do |rule|
        rule["type"] == "in_database" && rule["filter_from_code"]
      end

      if in_db_validation
        # Utiliser l'enum du code référencé
        source_code = in_db_validation["filter_from_code"]
        return dictionary[source_code]
      end
    end

    # Sinon, utiliser l'enum du code lui-même
    dictionary[code_str]
  end

  # Récupère la valeur lisible selon le type de code
  def get_readable_value(code_str, value, dictionary, validation_rules)
    case code_str
    when "C10"
      # Cas particulier : produits
      map_product_label_value(value)
    else
      # Cas général : déterminer quel dictionnaire utiliser
      dictionary_entry = get_dictionary_entry_for_mapping(code_str, validation_rules, dictionary)
      map_enum_value(value, dictionary_entry)
    end
  end
end
