# frozen_string_literal: true

require "test_helper"

class Api::HandshakeControllerTest < ActionDispatch::IntegrationTest
  test "identity returns public key" do
    get "/api/identity"
    assert_response :success
    body = JSON.parse(response.body)
    assert_equal "Ed25519", body["algorithm"]
    assert body["public_key"].present?
    assert body["key_version"].positive?
  end

  test "challenge rejects without auth" do
    post "/api/challenge", params: { nonce: SecureRandom.uuid, signature: "x" }, as: :json
    assert_response :unauthorized
  end

  test "challenge succeeds with valid inbound token and signature" do
    partner = Partner.create!(name: "Peer", code: "peer")
    peer_keys = Handshake::Crypto.generate_keypair
    inbound = "inbound-secret-token-value"

    connection = PartnerConnection.create!(
      partner: partner,
      remote_base_url: "http://peer.example.com",
      inbound_token: inbound,
      pinned_public_key: peer_keys[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keys[:public_key]),
      status: "pending"
    )

    nonce = SecureRandom.uuid
    signature = Handshake::Signing.sign_nonce(peer_keys[:private_key], nonce)

    post "/api/challenge",
         params: { nonce: nonce, signature: signature },
         headers: {
           "Authorization" => "Bearer #{inbound}",
           "X-Partner-Code" => "peer"
         },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_equal nonce, body["nonce"]
    assert Handshake::Signing.verify_nonce(
      Handshake::IdentityService.current.public_key,
      body["nonce"],
      body["signature"]
    )
    connection.reload
    assert connection.inbound_challenge_verified_at.present?
  end
end
