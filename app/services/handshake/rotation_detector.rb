# frozen_string_literal: true

module Handshake
  class RotationDetector
    class << self
      # Signature invalide + clé distante divergente → key_mismatch.
      # Retourne true si une rotation a été détectée et enregistrée.
      def call(partner)
        return false if partner.pinned_public_key.blank?
        return false if partner.remote_base_url.blank?

        remote = RemoteIdentity.fetch(partner)
        remote_fingerprint = Crypto.fingerprint(remote[:public_key])
        return false if partner.pinned_public_key_fingerprint == remote_fingerprint

        partner.mark_key_mismatch!
        true
      rescue RemoteIdentity::FetchError => e
        Rails.logger.warn("[Handshake::RotationDetector] partner=#{partner.id} #{e.message}")
        false
      end
    end
  end
end
