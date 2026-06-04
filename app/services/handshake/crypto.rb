# frozen_string_literal: true

require "ed25519"
require "base64"
require "digest"

module Handshake
  class Crypto
    class << self
      def generate_keypair
        signing_key = Ed25519::SigningKey.generate
        {
          public_key: Base64.strict_encode64(signing_key.verify_key.to_bytes),
          private_key: Base64.strict_encode64(signing_key.to_bytes)
        }
      end

      def sign(private_key_b64, message)
        signing_key = Ed25519::SigningKey.new(Base64.strict_decode64(private_key_b64))
        Base64.strict_encode64(signing_key.sign(message.to_s))
      end

      def verify(public_key_b64, signature_b64, message)
        verify_key = Ed25519::VerifyKey.new(Base64.strict_decode64(public_key_b64))
        verify_key.verify(Base64.strict_decode64(signature_b64), message.to_s)
        true
      rescue Ed25519::VerifyError, ArgumentError
        false
      end

      def fingerprint(public_key_b64)
        Digest::SHA256.hexdigest(Base64.strict_decode64(public_key_b64))
      end

      def secure_compare(a, b)
        return false if a.blank? || b.blank?

        ActiveSupport::SecurityUtils.secure_compare(a.to_s, b.to_s)
      end
    end
  end
end
