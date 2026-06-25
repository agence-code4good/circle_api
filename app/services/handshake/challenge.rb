# frozen_string_literal: true

module Handshake
  class Challenge
    class ChallengeError < StandardError
      attr_reader :code

      def initialize(message, code: "challenge_failed")
        super(message)
        @code = code
      end
    end

    def initialize(partner:, nonce:, signature:)
      @partner = partner
      @nonce = nonce
      @signature = signature
    end

    def call
      raise ChallengeError.new("Connexion suspendue", code: "connection_suspended") if @partner.handshake_status == "suspended"
      raise ChallengeError.new("Clé publique en attente", code: "key_mismatch") if @partner.handshake_status == "key_mismatch"
      raise ChallengeError.new("Clé publique non épinglée", code: "missing_public_key") if @partner.pinned_public_key.blank?
      raise ChallengeError.new("Nonce manquant", code: "missing_nonce") if @nonce.blank?
      raise ChallengeError.new("Signature invalide", code: "invalid_signature") unless verify_caller_signature

      unless NonceGuard.consume(partner: @partner, nonce: @nonce, purpose: "challenge")
        raise ChallengeError.new("Nonce rejoué", code: "nonce_replayed")
      end

      response_signature = Signing.sign_nonce(IdentityService.private_key, @nonce)

      @partner.update!(
        inbound_challenge_verified_at: Time.current,
        last_challenge_at: Time.current
      )
      @partner.activate_if_ready!

      { nonce: @nonce, signature: response_signature }
    end

    private

    def verify_caller_signature
      return true if Signing.verify_nonce(@partner.pinned_public_key, @nonce, @signature)

      if RotationDetector.call(@partner)
        raise ChallengeError.new("Rotation de clé détectée", code: "key_mismatch")
      end

      false
    end
  end
end
