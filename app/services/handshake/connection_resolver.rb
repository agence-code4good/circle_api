# frozen_string_literal: true

module Handshake
  class ConnectionResolver
    def self.for_incoming(partner_code:)
      return nil if partner_code.blank?

      Partner.find_by(code: partner_code)
    end

    def self.outbound_partner_code(partner)
      partner.outbound_partner_code
    end
  end
end
