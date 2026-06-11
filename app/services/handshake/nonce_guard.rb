# frozen_string_literal: true

module Handshake
  # Anti-replay guard. A nonce is single-use per connection: the first call that
  # records it wins, any later call with the same (connection, nonce) is rejected.
  #
  # Relies on the unique index on [partner_connection_id, nonce], so the check is
  # atomic across processes/workers and survives restarts (unlike a cache store,
  # which is :null_store in test and per-process in dev).
  class NonceGuard
    # TTL must cover the signature timestamp tolerance so a captured request can
    # never be replayed after its nonce row would have been pruned.
    TTL = Signing::TIMESTAMP_TOLERANCE.seconds + 60.seconds

    class << self
      # Returns true if the nonce was fresh and is now consumed, false if it was
      # already seen (replay) or is blank.
      def consume(connection:, nonce:, purpose:)
        return false if connection.blank? || nonce.blank?

        HandshakeNonce.create!(
          partner_connection: connection,
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
