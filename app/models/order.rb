class Order < ApplicationRecord
  has_many :order_lines, dependent: :destroy
  validates :buyer_id, presence: true
  validates :seller_id, presence: true
  validates :order_reference, presence: true
  validates :status, presence: true
  validates :order_lines, length: { minimum: 1 }
  validate :total_volume_cannot_change_on_update, on: :update
  validate :order_reference_cannot_change_on_update, on: :update

  accepts_nested_attributes_for :order_lines

  attr_accessor :original_total_volume

  before_validation :store_original_total_volume, on: :update, prepend: true

  enum :status, {
    nouvelle_commande: 1,
    en_attente_demande_de_mise: 2,
    demande_de_mise_et_logistique_en_cours: 3,
    details_de_mise_et_logistique_confirmes: 4,
    bon_de_commande: 5,
    mise_a_disposition: 6,
    bon_de_livraison: 7,
    commande_cloturee: 8
  }

  ALLOWED_TRANSITIONS = {
    "nouvelle_commande"                       => %w[en_attente_demande_de_mise],
    "en_attente_demande_de_mise"             => %w[demande_de_mise_et_logistique_en_cours details_de_mise_et_logistique_confirmes],
    "demande_de_mise_et_logistique_en_cours" => %w[details_de_mise_et_logistique_confirmes],
    "details_de_mise_et_logistique_confirmes"=> %w[bon_de_commande],
    "bon_de_commande"                         => %w[mise_a_disposition],
    "mise_a_disposition"                      => %w[bon_de_livraison],
    "bon_de_livraison"                        => %w[commande_cloturee]
  }.freeze

  # Vérifie si une transition de statut est autorisée
  def allowed_transition?(to_status)
    from_status = status.to_s
    allowed = ALLOWED_TRANSITIONS.fetch(from_status, [])
    allowed.include?(to_status.to_s)
  end

  def total_volume
    order_lines.sum(&:total_volume)
  end

  private

  def store_original_total_volume
    return if new_record?
    return if @original_total_volume # Ne pas recalculer si déjà stocké

    # Récupérer le volume total original depuis la base de données
    # sans affecter l'association order_lines qui contient les modifications en cours
    original_lines = OrderLine.where(order_id: id)
    @original_total_volume = original_lines.sum(&:total_volume)
  end

  def total_volume_cannot_change_on_update
    return if new_record?
    return unless @original_total_volume

    # Le volume total calculé inclut les modifications des nested attributes
    new_total_volume = total_volume
    if new_total_volume != @original_total_volume
      errors.add(:base, "Le volume total ne peut pas être modifié (était #{@original_total_volume}, devient #{new_total_volume})")
    end
  end

  def order_reference_cannot_change_on_update
    return if new_record?

    if order_reference_changed?
      errors.add(:order_reference, "ne peut pas être modifié après la création")
    end
  end
end
