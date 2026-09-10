# frozen_string_literal: true

module Handshake
  class IdentityService
    class MissingIdentityError < StandardError; end
    class ImportError < StandardError; end

    class << self
      def current
        InstanceIdentity.order(key_version: :desc).first
      end

      def require!
        current or raise MissingIdentityError, "Identité instance non configurée"
      end

      # Enregistre une identité fournie par CircUI (ou le SI intégrateur) à l'installation.
      # Pour une rotation, importer une nouvelle paire avec un key_version supérieur.
      def import!(public_key:, private_key:, key_version: 1)
        validate_keypair!(public_key, private_key)

        existing = current
        if existing
          raise ImportError, "key_version doit être supérieur à #{existing.key_version}" if key_version <= existing.key_version
        elsif key_version < 1
          raise ImportError, "key_version invalide"
        end

        InstanceIdentity.create!(
          public_key: public_key,
          private_key: private_key,
          key_version: key_version,
          rotated_at: Time.current
        )
      end

      # Dev / test uniquement — ne pas utiliser en intégration CircUI.
      def generate_for_dev!
        unless Rails.env.development? || Rails.env.test?
          raise ImportError, "La génération automatique est réservée au dev local"
        end

        return current if current.present?

        keypair = Crypto.generate_keypair
        import!(public_key: keypair[:public_key], private_key: keypair[:private_key], key_version: 1)
      end

      def public_payload(identity = nil)
        identity ||= require!
        {
          algorithm: "Ed25519",
          public_key: identity.public_key,
          key_version: identity.key_version
        }
      end

      def sign_with_instance(message)
        Crypto.sign(require!.private_key, message)
      end

      def private_key
        require!.private_key
      end

      private

      def validate_keypair!(public_key, private_key)
        raise ImportError, "clés manquantes" if public_key.blank? || private_key.blank?

        test_message = "circle-handshake-key-check"
        signature = Crypto.sign(private_key, test_message)
        return if Crypto.verify(public_key, signature, test_message)

        raise ImportError, "paire de clés Ed25519 invalide"
      end
    end
  end
end
