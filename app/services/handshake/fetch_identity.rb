# frozen_string_literal: true

module Handshake
  class FetchIdentity
    class FetchError < StandardError; end

    def initialize(partner, approve_rotation: false)
      @partner = partner
      @approve_rotation = approve_rotation
    end

    def call
      payload = RemoteIdentity.fetch(@partner)
      handle_tofu(payload[:public_key])
      payload
    rescue RemoteIdentity::FetchError => e
      raise FetchError, e.message
    end

    private

    def handle_tofu(public_key)
      fingerprint = Crypto.fingerprint(public_key)

      if @partner.pinned_public_key.blank?
        @partner.pin_public_key!(public_key)
        return
      end

      return if @partner.pinned_public_key_fingerprint == fingerprint

      if @approve_rotation
        @partner.pin_public_key!(public_key)
        return
      end

      @partner.mark_key_mismatch!
      raise FetchError, "Clé publique divergente (rotation détectée). Statut: key_mismatch."
    end
  end
end
