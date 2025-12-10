class Api::V1::CircleValuesController < Api::BaseController
  before_action :authenticate_partner!

  # Définition des dépendances supplémentaires (au-delà des champs de base C0, CLE, C10, C11)
  FIELD_DEPENDENCIES = {
    "C6" => %w[C1 C2 C3 C4 C5 C13],
    "C7" => %w[C1 C2 C3 C4 C5 C13],
    "C8" => %w[C1 C2 C3 C4 C5 C13],
    "C9" => %w[C1 C2 C3 C4 C5 C13],
    "C15" => %w[C13],
    "C16" => %w[C13],
    "C17" => %w[C13],
    "C18" => %w[C13],
    "C19" => %w[C13],
    "C22" => %w[C13],
    "C23" => %w[C13],
    "C24" => %w[C13],
    "C25" => %w[C13],
    "C37C" => %w[C13],
    "C39D" => %w[C1 C2 C3 C4 C5 C13]
  }.freeze

  def search
    # Récupérer les paramètres autorisés
    permitted_params = search_params
    input_values = (permitted_params[:input_values] || {}).to_h
    searched_values = permitted_params[:searched_values] || []

    # Vérifier les paramètres obligatoires
    required_fields = %w[C0 CLE C10 C11]
    missing_fields = required_fields.reject { |field| input_values[field].present? }

    if missing_fields.any?
      render json: { error: "Champs obligatoires manquants: #{missing_fields.join(', ')}" }, status: :bad_request
      return
    end

    # Valider la clé Circle (CLE)
    calculated_key = CircleKeyCalculatorService.new(input_values).calculate
    if calculated_key != input_values["CLE"]
      render json: { error: "Clé Circle invalide" }, status: :bad_request
      return
    end

    if searched_values.empty?
      render json: { error: "Aucun code recherché spécifié" }, status: :bad_request
      return
    end

    # Vérifier les dépendances pour chaque code recherché
    # Si le code n'est pas dans FIELD_DEPENDENCIES, il n'a besoin que des champs de base (déjà vérifiés)
    missing_dependencies = {}
    searched_values.each do |code|
      dependencies = FIELD_DEPENDENCIES[code]
      next unless dependencies # Pas de dépendances supplémentaires, seulement les champs de base

      missing = dependencies.reject { |dep| input_values[dep].present? }
      missing_dependencies[code] = missing if missing.any?
    end

    if missing_dependencies.any?
      error_messages = missing_dependencies.map do |code, deps|
        "Le code #{code} nécessite les champs suivants dans input_values: #{deps.join(', ')}"
      end
      render json: { error: error_messages.join("; ") }, status: :bad_request
      return
    end

    # Charger les données depuis le fichier JSON (à remplacer par des requêtes en DB)
    file_path = Rails.root.join("specs", "examples", "circle_data_example.json")
    unless File.exist?(file_path)
      render json: { error: "Fichier data.json non trouvé" }, status: :not_found
      return
    end

    data = JSON.parse(File.read(file_path))

    # Exclure CLE des input_values pour la recherche (la clé n'est pas utilisée pour trouver le hash)
    search_input_values = input_values.except("CLE")

    # Trouver le hash correspondant aux input_values (sans CLE)
    matching_hash = data.find do |hash|
      # Vérifier que tous les input_values correspondent (sans CLE)
      search_input_values.all? do |key, value|
        hash[key] == value.to_s
      end
    end

    unless matching_hash
      render json: { error: "Aucune donnée trouvée pour les valeurs d'entrée" }, status: :bad_request
      return
    end

    # Extraire les valeurs recherchées depuis le hash trouvé
    circle_values = {}
    searched_values.each do |code|
      if matching_hash.key?(code)
        circle_values[code] = {
          label: Validations::BaseValidation.dictionary[code]["label"],
          value: matching_hash[code],
          circle_value: Validations::BaseValidation.dictionary[code]["enum"][matching_hash[code]] || matching_hash[code]
        }
      end
    end

    render json: { circle_values: circle_values }, status: :ok
  end

  private

  def search_params
    params.permit(input_values: {}, searched_values: [])
  end
end
