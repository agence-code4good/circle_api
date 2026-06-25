# frozen_string_literal: true

require "test_helper"

class Api::HandshakeControllerTest < ActionDispatch::IntegrationTest
  test "identity returns service unavailable when not configured" do
    InstanceIdentity.delete_all

    get "/api/identity"
    assert_response :service_unavailable
    assert_equal "identity_not_configured", JSON.parse(response.body)["error"]
  end

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

  test "challenge succeeds with valid token and signature" do
    peer_keys = Handshake::Crypto.generate_keypair
    inbound = "inbound-secret-token-value"

    partner = Partner.create!(
      name: "Peer",
      code: "peer",
      remote_base_url: "http://peer.example.com",
      auth_token_for_set: inbound,
      pinned_public_key: peer_keys[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keys[:public_key]),
      handshake_status: "pending"
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
    partner.reload
    assert partner.inbound_challenge_verified_at.present?
    assert_equal "active", partner.handshake_status
  end

  test "challenge rejects a replayed nonce" do
    peer_keys = Handshake::Crypto.generate_keypair
    inbound = "inbound-secret-token-value"

    Partner.create!(
      name: "Peer",
      code: "peer",
      remote_base_url: "http://peer.example.com",
      auth_token_for_set: inbound,
      pinned_public_key: peer_keys[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keys[:public_key]),
      handshake_status: "pending"
    )

    nonce = SecureRandom.uuid
    signature = Handshake::Signing.sign_nonce(peer_keys[:private_key], nonce)
    headers = { "Authorization" => "Bearer #{inbound}", "X-Partner-Code" => "peer" }

    post "/api/challenge", params: { nonce: nonce, signature: signature }, headers: headers, as: :json
    assert_response :success

    post "/api/challenge", params: { nonce: nonce, signature: signature }, headers: headers, as: :json
    assert_response :unauthorized
    assert_equal "nonce_replayed", JSON.parse(response.body)["error"]
  end

  test "invalid signature with rotated remote key marks key_mismatch" do
    old_key = Handshake::Crypto.generate_keypair
    new_key = Handshake::Crypto.generate_keypair
    inbound = "inbound-secret"

    partner = Partner.create!(
      name: "Peer",
      code: "peer",
      remote_base_url: "http://peer.example.com",
      auth_token_for_set: inbound,
      pinned_public_key: old_key[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(old_key[:public_key]),
      handshake_status: "active",
      inbound_challenge_verified_at: Time.current
    )

    nonce = SecureRandom.uuid
    challenge_signature = Handshake::Signing.sign_nonce(new_key[:private_key], nonce)

    stub_remote_identity_fetch(public_key: new_key[:public_key], key_version: 2, algorithm: "Ed25519") do
      post "/api/challenge",
           params: { nonce: nonce, signature: challenge_signature },
           headers: { "Authorization" => "Bearer #{inbound}", "X-Partner-Code" => "peer" },
           as: :json
    end

    assert_response :forbidden
    assert_equal "key_mismatch", JSON.parse(response.body)["error"]
    assert_equal "key_mismatch", partner.reload.handshake_status
  end

  test "challenge on key_mismatch partner returns forbidden" do
    peer_keys = Handshake::Crypto.generate_keypair
    inbound = "inbound-secret-token-value"

    Partner.create!(
      name: "Peer",
      code: "peer",
      remote_base_url: "http://peer.example.com",
      auth_token_for_set: inbound,
      pinned_public_key: peer_keys[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keys[:public_key]),
      handshake_status: "key_mismatch"
    )

    nonce = SecureRandom.uuid
    signature = Handshake::Signing.sign_nonce(peer_keys[:private_key], nonce)

    post "/api/challenge",
         params: { nonce: nonce, signature: signature },
         headers: { "Authorization" => "Bearer #{inbound}", "X-Partner-Code" => "peer" },
         as: :json

    assert_response :forbidden
    assert_equal "key_mismatch", JSON.parse(response.body)["error"]
  end
end
