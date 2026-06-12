# frozen_string_literal: true

module Handshake
  class ConnectionResolver
    def self.for_incoming(partner_code:)
      return nil if partner_code.blank?

      # On ne filtre pas sur le statut ici : c'est l'appelant
      # (connection_allows_exchange? / Handshake::Challenge) qui décide du code
      # d'erreur. Exclure les connexions suspendues les rendrait indistinguables
      # d'un partenaire inconnu (401) au lieu d'un 403 connection_suspended explicite.
      #
      # S'il existe plusieurs connexions pour ce partenaire, on privilégie la
      # connexion active (au plus une, garantie par le modèle) ; sinon on retombe
      # sur la plus récente pour produire le bon message d'erreur.
      scope = PartnerConnection.joins(:partner).where(partners: { code: partner_code })
      scope.active.first || scope.order(updated_at: :desc).first
    end

    def self.outbound_partner_code(connection)
      connection.linkage_code_remote.presence ||
        Rails.application.config.handshake_instance_code
    end
  end
end
