# frozen_string_literal: true

module Handshake
  class ConnectionResolver
    def self.for_incoming(partner_code:)
      return nil if partner_code.blank?

      scope = PartnerConnection.joins(:partner).where(partners: { code: partner_code })
      scope.active.first || scope.order(updated_at: :desc).first
    end

    def self.outbound_partner_code(connection)
      connection.linkage_code_remote.presence ||
        Rails.application.config.handshake_instance_code
    end
  end
end
