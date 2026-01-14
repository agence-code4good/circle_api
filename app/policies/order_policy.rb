# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  BUYER_ONLY  = %w[
    nouvelle_commande
    demande_de_mise_et_logistique_en_cours
    details_de_mise_et_logistique_confirmes
    commande_cloturee
    annulee_acheteur
  ].freeze

  SELLER_ONLY = %w[
    en_attente_demande_de_mise
    bon_de_commande
    mise_a_disposition
    bon_de_livraison
    annulee_vendeur
  ].freeze

  # Statuts où les order_lines ne sont plus modifiables par personne
  ORDER_LINES_LOCKED_STATUSES = %w[
    mise_a_disposition
    bon_de_livraison
    commande_cloturee
  ].freeze

  # Statuts où les order_lines ne sont modifiables que par le seller
  ORDER_LINES_SELLER_ONLY_STATUSES = %w[
    details_de_mise_et_logistique_confirmes
    bon_de_commande
  ].freeze

  # Autorisation "générale" d'action
  def create?
    # Vérifier que le user authentifié est le buyer
    actor_role == :buyer
  end

  def update?
    # Vérifier que le user authentifié est le buyer ou le seller
    actor_role == :buyer || actor_role == :seller
  end

  # Vérifie si les order_lines peuvent être modifiées
  def can_modify_order_lines?
    return false unless record

    current_status = record.status.to_s

    # Si le statut est verrouillé, personne ne peut modifier
    return false if ORDER_LINES_LOCKED_STATUSES.include?(current_status)

    # Si le statut nécessite que ce soit le seller, vérifier le rôle
    if ORDER_LINES_SELLER_ONLY_STATUSES.include?(current_status)
      return actor_role == :seller
    end

    # Sinon, autoriser si c'est le buyer ou le seller
    actor_role == :buyer || actor_role == :seller
  end

  # Vérifie que le statut demandé est autorisé pour le rôle de l'utilisateur
  # to_status: String (ex: "bon_de_commande")
  def allowed_status?(to_status)
    return false unless record && user.is_a?(Partner)
    
    current_status = record.status.to_s
    
    # Logique spéciale pour l'annulation finale "annulee"
    if to_status == "annulee"
      # Depuis annulee_acheteur, seul le seller peut confirmer
      return actor_role == :seller if current_status == "annulee_acheteur"
      # Depuis annulee_vendeur, seul le buyer peut confirmer
      return actor_role == :buyer if current_status == "annulee_vendeur"
      # Sinon, personne ne peut directement passer à "annulee"
      return false
    end
    
    # Logique pour le retour au statut précédent depuis annulee_acheteur ou annulee_vendeur
    if current_status.in?(%w[annulee_acheteur annulee_vendeur])
      # Les deux parties peuvent revenir au statut précédent
      if record.previous_status.present?
        previous_status_key = Order.statuses.key(record.previous_status)
        return true if to_status == previous_status_key && (actor_role == :buyer || actor_role == :seller)
      end
    end
    
    # Vérifier que le statut demandé est dans la liste autorisée pour le rôle
    case actor_role
    when :buyer  then BUYER_ONLY.include?(to_status)
    when :seller then SELLER_ONLY.include?(to_status)
    else false
    end
  end

  # Définit le rôle l'utilisateur authentifié sur CETTE commande
  def actor_role
    return nil unless user.is_a?(Partner) && record

    if record.buyer_id == user.code
      :buyer
    elsif record.seller_id == user.code
      :seller
    else
      nil
    end
  end

  class Scope < ApplicationPolicy::Scope
    def resolve
      # Filtrer les commandes visibles par l'utilisateur authentifié'
      scope
    end
  end
end
