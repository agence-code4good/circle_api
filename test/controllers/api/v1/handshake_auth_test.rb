# frozen_string_literal: true

require "test_helper"

class Api::V1::HandshakeAuthTest < ActionDispatch::IntegrationTest
  test "products index requires handshake signature" do
    partner = create_handshake_partner!(code: "test_partner")

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
