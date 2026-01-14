class Order < ApplicationRecord
  has_many :order_lines, dependent: :destroy
  validates :buyer_id, presence: true
  validates :seller_id, presence: true
  validates :order_reference, presence: true
  validates :status, presence: true
  validates :order_reference, uniqueness: true, presence: true
  validates :order_lines, length: { minimum: 1 }

  validates :accompanying_document_url,
            format: { with: URI::DEFAULT_PARSER.make_regexp(%w[https]), message: "doit être une url https valide" },
            allow_blank: true

  validate :latest_instruction_due_date_must_be_future_or_today, on: :create
  validate :estimated_availability_earliest_at_must_be_future_or_today, on: :create
  validate :status_must_be_nouvelle_commande_on_create, on: :create
  validate :total_volume_cannot_change_on_update, on: :update
  validate :order_reference_cannot_change_on_update, on: :update
  validate :status_is_valid
  validate :status_transition_is_allowed, on: :update
  validate :initial_order_reference_exists

  accepts_nested_attributes_for :order_lines

  attr_accessor :original_total_volume
  attr_accessor :original_volumes_by_group

  before_validation :store_original_total_volume, on: :update, prepend: true
  before_save :store_previous_status_on_status_change

  enum :status, {
    nouvelle_commande: 1,
    en_attente_demande_de_mise: 2,
    demande_de_mise_et_logistique_en_cours: 3,
    details_de_mise_et_logistique_confirmes: 4,
    bon_de_commande: 5,
    mise_a_disposition: 6,
    bon_de_livraison: 7,
    commande_cloturee: 8,
    annulee_acheteur: 9,
    annulee_vendeur: 10,
    annulee: 11
  }

  ALLOWED_TRANSITIONS = {
    "nouvelle_commande"                       => %w[en_attente_demande_de_mise annulee_acheteur annulee_vendeur],
    "en_attente_demande_de_mise"             => %w[demande_de_mise_et_logistique_en_cours details_de_mise_et_logistique_confirmes annulee_acheteur annulee_vendeur],
    "demande_de_mise_et_logistique_en_cours" => %w[details_de_mise_et_logistique_confirmes annulee_acheteur annulee_vendeur],
    "details_de_mise_et_logistique_confirmes"=> %w[bon_de_commande annulee_acheteur annulee_vendeur],
    "bon_de_commande"                         => %w[mise_a_disposition annulee_acheteur annulee_vendeur],
    "mise_a_disposition"                      => %w[bon_de_livraison annulee_acheteur annulee_vendeur],
    "bon_de_livraison"                        => %w[commande_cloturee annulee_acheteur annulee_vendeur],
    "annulee_acheteur"                        => %w[annulee],
    "annulee_vendeur"                         => %w[annulee],
    "commande_cloturee"                       => [],
    "annulee"                                 => []
  }.freeze

  ## Ransackable attributes pour la recherche dans l'admin ##
  def self.ransackable_attributes(auth_object = nil)
    [ "buyer_id", "created_at", "id", "id_value", "note", "order_reference", "seller_id", "status", "updated_at", "accompanying_document_url", "latest_instruction_due_date", "estimated_availability_earliest_at" ]
  end

  ## Méthodes liées à l'Order ##

  def total_volume
    order_lines.sum(&:total_volume)
  end

  # Prépare la suppression/recréation des order_lines en stockant les volumes originaux
  def prepare_order_lines_replacement
    return if new_record?

    # Stocker les volumes originaux AVANT de supprimer les order_lines
    original_lines = OrderLine.from_order_reference(order_reference)
    @original_volumes_by_group = {}
    original_lines.each do |line|
      group_key = group_key_for_line(line.circle_code)
      @original_volumes_by_group[group_key] ||= 0
      @original_volumes_by_group[group_key] += line.total_volume
    end
  end

  ## Validations liées à l'Order ##

  # Vérifie que le statut est valide
  def status_is_valid
    unless Order.statuses.key?(status)
      errors.add(:status, "n'est pas un statut valide")
    end
  rescue ArgumentError
    errors.add(:status, "n'est pas une valeur valide")
  end


  # Vérifie que le statut est "nouvelle_commande" pour une nouvelle commande
  def status_must_be_nouvelle_commande_on_create
    return unless new_record?

    unless status.to_s == "nouvelle_commande"
      errors.add(:status, "doit être 'nouvelle_commande' pour les nouvelles commandes")
    end
  end

  # Vérifie si une transition de statut est autorisée
  def allowed_transition?(to_status, from_status: nil)
    from_status ||= status.to_s
    
    # Gérer le retour au statut précédent depuis annulee_acheteur ou annulee_vendeur
    if (from_status == "annulee_acheteur" || from_status == "annulee_vendeur") && 
       previous_status.present?
      previous_status_key = Order.statuses.key(previous_status)
      return true if to_status == previous_status_key
    end
    
    # Vérifier les transitions autorisées dans la map
    allowed = ALLOWED_TRANSITIONS.fetch(from_status, [])
    allowed.include?(to_status.to_s)
  end

  private

  # Sauvegarde systématiquement le statut précédent à chaque changement de statut
  def store_previous_status_on_status_change
    return if new_record?  # Pas de previous_status pour une nouvelle commande
    return unless status_changed?  # Seulement si le statut change
    
    # Sauvegarder le statut précédent
    self.previous_status = Order.statuses[status_was]
  end

  def store_original_total_volume
    return if new_record?
    return if @original_volumes_by_group # Ne pas recalculer si déjà stocké

    # Récupérer les order_lines originales depuis la base de données
    # sans affecter l'association order_lines qui contient les modifications en cours
    original_lines = OrderLine.where(order_id: id)

    # Grouper par combinaison C10/C11 et calculer le volume total de chaque groupe
    @original_volumes_by_group = {}
    original_lines.each do |line|
      group_key = group_key_for_line(line.circle_code)
      @original_volumes_by_group[group_key] ||= 0
      @original_volumes_by_group[group_key] += line.total_volume
    end
  end

  # Vérifie que le volume total du couple C10/C11 ne peut pas être modifié après la création
  def total_volume_cannot_change_on_update
    return if new_record?
    return unless @original_volumes_by_group

    # Calculer les nouveaux volumes par groupe C10/C11
    new_volumes_by_group = {}
    order_lines.each do |line|
      next if line.marked_for_destruction?

      group_key = group_key_for_line(line.circle_code)
      new_volumes_by_group[group_key] ||= 0
      new_volumes_by_group[group_key] += line.total_volume
    end

    # Vérifier que chaque groupe a le même volume total
    all_group_keys = (@original_volumes_by_group.keys + new_volumes_by_group.keys).uniq

    all_group_keys.each do |group_key|
      original_volume = @original_volumes_by_group[group_key] || 0
      new_volume = new_volumes_by_group[group_key] || 0

      if original_volume != new_volume
        errors.add(:base, "Le volume total pour le groupe #{group_key} ne peut pas être modifié (était #{original_volume}, devient #{new_volume})")
      end
    end
  end

  # Vérifie que la référence de commande ne peut pas être modifiée après la création
  def order_reference_cannot_change_on_update
    return if new_record?

    if order_reference_changed?
      errors.add(:order_reference, "ne peut pas être modifié après la création")
    end
  end

  # Vérifie que la référence de commande initiale existe
  def initial_order_reference_exists
    return if initial_order_reference.blank?
    initial_order = Order.find_by(order_reference: initial_order_reference)
    unless initial_order
      errors.add(:initial_order_reference, "doit être une référence de commande existante")
    end
  end

  # Vérifie que la transition de statut est autorisée
  def status_transition_is_allowed
    return if new_record?
    return unless status_changed?

    unless allowed_transition?(status, from_status: status_was)
      errors.add(:status, "Transition de statut invalide de '#{status_was}' à '#{status}'")
    end
  end

  # Vérifie que la date d'instruction de mise au plus tard est posterieure à la date du jour
  def latest_instruction_due_date_must_be_future_or_today
    return if latest_instruction_due_date.blank?

    if latest_instruction_due_date < Date.current
      errors.add(:latest_instruction_due_date, "doit être posterieur à la date du jour")
    end
  end

  # Vérifie que la date date de mise à disposition estimée au plus tôt de la commande est posterieure à la date du jour
  def estimated_availability_earliest_at_must_be_future_or_today
    return if estimated_availability_earliest_at.blank?

    if estimated_availability_earliest_at < Date.current
      errors.add(:estimated_availability_earliest_at, "doit être posterieur à la date du jour")
    end
  end

  # Génère une clé unique pour un groupe basée sur C10 et C11
  def group_key_for_line(circle_code)
    "#{circle_code["C10"]}|#{circle_code["C11"]}"
  end
end
