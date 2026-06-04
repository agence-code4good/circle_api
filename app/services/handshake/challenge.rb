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

    def initialize(connection:, nonce:, signature:)
      @connection = connection
      @nonce = nonce
      @signature = signature
    end

    def call
      raise ChallengeError.new("Connexion suspendue", code: "connection_suspended") if @connection.status == "suspended"
      raise ChallengeError.new("Clé publique en attente", code: "key_mismatch") if @connection.status == "key_mismatch"
      raise ChallengeError.new("Clé publique non épinglée", code: "missing_public_key") if @connection.pinned_public_key.blank?
      raise ChallengeError.new("Nonce manquant", code: "missing_nonce") if @nonce.blank?
      raise ChallengeError.new("Signature invalide", code: "invalid_signature") unless verify_caller_signature

      response_signature = Signing.sign_nonce(IdentityService.private_key, @nonce)

      @connection.update!(
        inbound_challenge_verified_at: Time.current,
        last_challenge_at: Time.current
      )
      @connection.activate_if_ready!

      { nonce: @nonce, signature: response_signature }
    end

    private

    def verify_caller_signature
      Signing.verify_nonce(@connection.pinned_public_key, @nonce, @signature)
    end
  end
end
