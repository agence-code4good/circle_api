# frozen_string_literal: true

module Handshake
  class IdentityService
    class << self
      def current
        InstanceIdentity.order(key_version: :desc).first
      end

      def ensure!
        return current if current.present?

        generate!
      end

      def generate!
        keypair = Crypto.generate_keypair
        version = (current&.key_version || 0) + 1

        InstanceIdentity.create!(
          public_key: keypair[:public_key],
          private_key: keypair[:private_key],
          key_version: version,
          rotated_at: Time.current
        )
      end

      def rotate!
        generate!
      end

      def public_payload(identity = current)
        identity ||= ensure!
        {
          algorithm: "Ed25519",
          public_key: identity.public_key,
          key_version: identity.key_version
        }
      end

      def sign_with_instance(message)
        identity = ensure!
        Crypto.sign(identity.private_key, message)
      end

      def private_key
        ensure!.private_key
      end
    end
  end
end
