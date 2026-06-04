# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"

module Handshake
  class ChallengeClient
    class ClientError < StandardError; end

    def initialize(connection)
      @connection = connection
    end

    def call
      raise ClientError, "Token outbound manquant" if @connection.outbound_token.blank?
      raise ClientError, "Clé publique partenaire non épinglée" if @connection.pinned_public_key.blank?

      Handshake::IdentityService.ensure!
      nonce = SecureRandom.uuid
      signature = Signing.sign_nonce(IdentityService.private_key, nonce)

      response = post_challenge(nonce, signature)
      raise ClientError, "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      verify_response!(body)

      @connection.update!(
        outbound_challenge_verified_at: Time.current,
        last_challenge_at: Time.current
      )
      @connection.activate_if_ready!

      body
    end

    private

    def post_challenge(nonce, signature)
      uri = URI.parse("#{OutboundUrl.resolve(@connection.remote_base_url)}/api/challenge")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@connection.outbound_token}"
      request["X-Partner-Code"] = ConnectionResolver.outbound_partner_code(@connection)
      request["Content-Type"] = "application/json"
      request.body = { nonce: nonce, signature: signature }.to_json

      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
        http.request(request)
      end
    end

    def verify_response!(body)
      nonce = body["nonce"]
      signature = body["signature"]
      raise ClientError, "Réponse challenge invalide" if nonce.blank? || signature.blank?
      raise ClientError, "Signature réponse invalide" unless Signing.verify_nonce(@connection.pinned_public_key, nonce, signature)
    end
  end
end
