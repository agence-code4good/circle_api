# frozen_string_literal: true

require "json"
require "net/http"
require "securerandom"
require "openssl"
require "base64"
require "ed25519"

# Client Handshake v2 pour les appels API Circle.
# Voir specs/handshake_v2_signing.md
class HandshakeClient
  def initialize(base_url:, partner_code:, inbound_token:, peer_public_key_b64:, peer_private_key_b64:)
    @base_url = base_url.chomp("/")
    @partner_code = partner_code
    @inbound_token = inbound_token
    @peer_public_key_b64 = peer_public_key_b64
    @peer_private_key_b64 = peer_private_key_b64
  end

  def fetch_identity
    get("/api/identity")
  end

  def challenge(remote_base_url:, outbound_token:, our_private_key_b64:, linkage_code_remote:)
    nonce = SecureRandom.uuid
    signing_key = Ed25519::SigningKey.new(Base64.strict_decode64(our_private_key_b64))
    signature = Base64.strict_encode64(signing_key.sign(nonce))

    uri = URI.parse("#{remote_base_url.chomp('/')}/api/challenge")
    request = Net::HTTP::Post.new(uri)
    request["Authorization"] = "Bearer #{outbound_token}"
    request["X-Partner-Code"] = linkage_code_remote
    request["Content-Type"] = "application/json"
    request.body = { nonce: nonce, signature: signature }.to_json

    response = http_request(uri, request)
    JSON.parse(response.body)
  end

  def signed_headers(method:, path:, body: "")
    nonce = SecureRandom.uuid
    timestamp = Time.now.to_i.to_s
    body_hash = Digest::SHA256.hexdigest(body.to_s)
    canonical = [ method.upcase, path, body_hash, nonce, timestamp ].join("\n")
    signing_key = Ed25519::SigningKey.new(Base64.strict_decode64(@peer_private_key_b64))
    signature = Base64.strict_encode64(signing_key.sign(canonical))

    {
      "Authorization" => "Bearer #{@inbound_token}",
      "X-Partner-Code" => @partner_code,
      "X-Handshake-Nonce" => nonce,
      "X-Handshake-Timestamp" => timestamp,
      "X-Handshake-Signature" => signature,
      "Content-Type" => "application/json"
    }
  end

  private

  def get(path)
    uri = URI.parse("#{@base_url}#{path}")
    request = Net::HTTP::Get.new(uri)
    response = http_request(uri, request)
    JSON.parse(response.body)
  end

  def http_request(uri, request)
    Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https") do |http|
      http.request(request)
    end
  end
end
