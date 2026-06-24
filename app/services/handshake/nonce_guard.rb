# frozen_string_literal: true

module Handshake
  class NonceGuard
    TTL = Signing::TIMESTAMP_TOLERANCE.seconds + 60.seconds
    class << self
      def consume(partner:, nonce:, purpose:)
        return false if partner.blank? || nonce.blank?

        HandshakeNonce.create!(
          partner: partner,
          nonce: nonce,
          purpose: purpose,
          expires_at: TTL.from_now
        )
        true
      rescue ActiveRecord::RecordNotUnique
        false
      end

      def prune_expired
        HandshakeNonce.expired.delete_all
      end
    end
  end
end
