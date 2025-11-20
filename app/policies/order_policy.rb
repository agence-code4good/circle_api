# frozen_string_literal: true

class OrderPolicy < ApplicationPolicy
  BUYER_ONLY  = %w[
    demande_de_mise_et_logistique_en_cours
    details_de_mise_et_logistique_confirmes
    commande_cloturee
  ].freeze

  SELLER_ONLY = %w[
    nouvelle_commande
    en_attente_demande_de_mise
    bon_de_commande
    mise_a_disposition
    bon_de_livraison
  ].freeze

  # Autorisation "générale" d'action
  def create?
    # Vérifier que le user authentifié est le buyer
    true
  end

  def update?
    true
  end

  # Vérifie que le statut demandé est autorisé pour le rôle de l'utilisateur
  # to_status: String (ex: "bon_de_commande")
  def allowed_status?(to_status)
    case actor_role
    when :buyer  then BUYER_ONLY.include?(to_status)
    when :seller then SELLER_ONLY.include?(to_status)
    else false
    end
  end

  # Déduis le rôle effectif de l'acteur sur CETTE commande
  # Implémente ici ta logique: appariement clé API ↔ paire buyer/seller, etc.
  def actor_role
    return nil unless user.is_a?(Partner) && record

    buyer_id = record.buyer_id
    return nil unless buyer_id

    buyer_partner = buyer_partner_for(buyer_id)
    return nil unless buyer_partner

    if buyer_partner == user
      :buyer
    elsif record.seller_id && seller_partner_for(record.seller_id) == user
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

  private

  # Détermine le partner buyer à partir d'un buyer_id
  # Si buyer_id correspond à partner_alias, retourne le partner de l'identifier_pair
  # Si buyer_id correspond à my_alias, retourne le partner Circle (main_partner)
  def buyer_partner_for(buyer_id)
    return nil unless buyer_id

    identifier_pair = IdentifierPair.find_by(partner_alias: buyer_id) || IdentifierPair.find_by(my_alias: buyer_id)
    return nil unless identifier_pair

    if identifier_pair.partner_alias == buyer_id
      identifier_pair.partner
    else
      Partner.main_partner
    end
  end

  # Détermine le partner seller à partir d'un seller_id
  # Même logique que pour le buyer
  def seller_partner_for(seller_id)
    return nil unless seller_id

    identifier_pair = IdentifierPair.find_by(partner_alias: seller_id) || IdentifierPair.find_by(my_alias: seller_id)
    return nil unless identifier_pair

    if identifier_pair.partner_alias == seller_id
      identifier_pair.partner
    else
      Partner.main_partner
    end
  end
end
