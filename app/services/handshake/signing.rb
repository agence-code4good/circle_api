# frozen_string_literal: true

require "digest"

module Handshake
  class Signing
    TIMESTAMP_TOLERANCE = 300

    class << self
      def canonical_message(method:, path:, body:, nonce:, timestamp:)
        body_hash = Digest::SHA256.hexdigest(body.to_s)
        [ method.to_s.upcase, path, body_hash, nonce, timestamp.to_s ].join("\n")
      end

      def sign_request(private_key_b64:, method:, path:, body:, nonce:, timestamp:)
        message = canonical_message(
          method: method,
          path: path,
          body: body,
          nonce: nonce,
          timestamp: timestamp
        )
        Crypto.sign(private_key_b64, message)
      end

      def verify_request(public_key_b64:, method:, path:, body:, nonce:, timestamp:, signature_b64:)
        return false unless timestamp_valid?(timestamp)

        message = canonical_message(
          method: method,
          path: path,
          body: body,
          nonce: nonce,
          timestamp: timestamp
        )
        Crypto.verify(public_key_b64, signature_b64, message)
      end

      def sign_nonce(private_key_b64, nonce)
        Crypto.sign(private_key_b64, nonce)
      end

      def verify_nonce(public_key_b64, nonce, signature_b64)
        Crypto.verify(public_key_b64, signature_b64, nonce)
      end

      def timestamp_valid?(timestamp)
        ts = Integer(timestamp)
        (Time.now.to_i - ts).abs <= TIMESTAMP_TOLERANCE
      rescue ArgumentError, TypeError
        false
      end
    end
  end
end
