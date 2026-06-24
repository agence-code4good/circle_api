# frozen_string_literal: true

require "net/http"
require "json"
require "securerandom"

module Handshake
  class ChallengeClient
    class ClientError < StandardError; end

    def initialize(partner, outbound_token:)
      @partner = partner
      @outbound_token = outbound_token
    end

    def call
      raise ClientError, "Token outbound manquant" if @outbound_token.blank?
      raise ClientError, "Clé publique partenaire non épinglée" if @partner.pinned_public_key.blank?

      nonce = SecureRandom.uuid
      signature = Signing.sign_nonce(IdentityService.private_key, nonce)

      response = post_challenge(nonce, signature)
      raise ClientError, "HTTP #{response.code}: #{response.body}" unless response.is_a?(Net::HTTPSuccess)

      body = JSON.parse(response.body)
      verify_response!(body)

      @partner.record_outbound_challenge!

      body
    end

    private

    def post_challenge(nonce, signature)
      uri = URI.parse("#{OutboundUrl.resolve(@partner.remote_base_url)}/api/challenge")
      request = Net::HTTP::Post.new(uri)
      request["Authorization"] = "Bearer #{@outbound_token}"
      request["X-Partner-Code"] = ConnectionResolver.outbound_partner_code(@partner)
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
      raise ClientError, "Signature réponse invalide" unless Signing.verify_nonce(@partner.pinned_public_key, nonce, signature)
    end
  end
end
