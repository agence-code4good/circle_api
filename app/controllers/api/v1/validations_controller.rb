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
    results = []

    # Créer un index basé sur l'ordre des clés dans le dictionnaire YAML
    dictionary_order = dictionary.keys.each_with_index.to_h

    circle_values.each do |code, value|
      code_str = code.to_s
      dictionary_entry = dictionary[code_str]

      # Récupérer le label depuis le dictionnaire
      label = dictionary_entry&.dig("label") || code_str

      # Récupérer la valeur lisible depuis l'enum (gère les arrays imbriqués récursivement)
      enum_value = map_enum_value(value, dictionary_entry)

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
end
