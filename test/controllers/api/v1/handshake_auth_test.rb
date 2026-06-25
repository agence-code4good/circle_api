# frozen_string_literal: true

require "test_helper"

class Api::V1::HandshakeAuthTest < ActionDispatch::IntegrationTest
  test "invalid signature with rotated remote key marks key_mismatch" do
    old_key = Handshake::Crypto.generate_keypair
    new_key = Handshake::Crypto.generate_keypair
    inbound = "secret-inbound"

    partner = Partner.create!(
      name: "Rotated",
      code: "rotated_peer",
      remote_base_url: "http://peer.example.com",
      auth_token_for_set: inbound,
      pinned_public_key: old_key[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(old_key[:public_key]),
      handshake_status: "active",
      inbound_challenge_verified_at: Time.current,
      outbound_challenge_verified_at: Time.current
    )

    body = ""
    nonce = SecureRandom.uuid
    timestamp = Time.now.to_i.to_s
    signature = Handshake::Signing.sign_request(
      private_key_b64: new_key[:private_key],
      method: "GET",
      path: "/api/v1/products",
      body: body,
      nonce: nonce,
      timestamp: timestamp
    )

    headers = {
      "Authorization" => "Bearer #{inbound}",
      "X-Partner-Code" => partner.code,
      "X-Handshake-Nonce" => nonce,
      "X-Handshake-Timestamp" => timestamp,
      "X-Handshake-Signature" => signature
    }

    stub_remote_identity_fetch(public_key: new_key[:public_key], key_version: 2, algorithm: "Ed25519") do
      get "/api/v1/products", headers: headers
    end

    assert_response :forbidden
    assert_equal "key_mismatch", JSON.parse(response.body)["error"]
    assert_equal "key_mismatch", partner.reload.handshake_status
  end

  test "products index requires handshake signature" do
    partner = create_handshake_partner!(code: "test_partner", remote_url: "http://127.0.0.1:1")

    get "/api/v1/products",
        headers: { "Authorization" => "Bearer #{partner.auth_token_plain}", "X-Partner-Code" => partner.code }

    assert_response :unauthorized
    assert_equal "invalid_signature", JSON.parse(response.body)["error"]
  end

  test "products index succeeds with valid signature" do
    partner = create_handshake_partner!(code: "test_partner")
    headers = signed_headers(partner: partner, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :success
  end

  test "replaying the same signed request is rejected" do
    partner = create_handshake_partner!(code: "test_partner")
    headers = signed_headers(partner: partner, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :success

    get "/api/v1/products", headers: headers
    assert_response :unauthorized
    assert_equal "nonce_replayed", JSON.parse(response.body)["error"]
  end

  test "suspended partner returns explicit 403 connection_suspended" do
    partner = create_handshake_partner!(code: "test_partner", handshake_status: "suspended")
    headers = signed_headers(partner: partner, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :forbidden
    assert_equal "connection_suspended", JSON.parse(response.body)["error"]
  end

  test "pending partner returns connection_not_active" do
    partner = create_handshake_partner!(code: "test_partner", handshake_status: "pending")
    headers = signed_headers(partner: partner, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :forbidden
    assert_equal "connection_not_active", JSON.parse(response.body)["error"]
  end
end
