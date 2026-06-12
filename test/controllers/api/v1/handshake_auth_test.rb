# frozen_string_literal: true

require "test_helper"

class Api::V1::HandshakeAuthTest < ActionDispatch::IntegrationTest
  test "products index requires handshake signature" do
    partner = Partner.create!(name: "Test", code: "test_partner")
    connection = create_partner_connection!(partner: partner, inbound_token: "secret-inbound")

    get "/api/v1/products",
        headers: { "Authorization" => "Bearer #{connection.inbound_token}", "X-Partner-Code" => partner.code }

    assert_response :unauthorized
    assert_equal "invalid_signature", JSON.parse(response.body)["error"]
  end

  test "products index succeeds with valid signature" do
    partner = Partner.create!(name: "Test", code: "test_partner")
    connection = create_partner_connection!(partner: partner, inbound_token: "secret-inbound")

    headers = signed_headers(connection: connection, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :success
  end

  test "replaying the same signed request is rejected" do
    partner = Partner.create!(name: "Test", code: "test_partner")
    connection = create_partner_connection!(partner: partner, inbound_token: "secret-inbound")

    headers = signed_headers(connection: connection, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :success

    # Same nonce/signature replayed within the timestamp window.
    get "/api/v1/products", headers: headers
    assert_response :unauthorized
    assert_equal "nonce_replayed", JSON.parse(response.body)["error"]
  end

  test "suspended connection returns explicit 403 connection_suspended" do
    partner = Partner.create!(name: "Test", code: "test_partner")
    connection = create_partner_connection!(partner: partner, inbound_token: "secret-inbound", status: "suspended")

    headers = signed_headers(connection: connection, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :forbidden
    assert_equal "connection_suspended", JSON.parse(response.body)["error"]
  end

  test "active connection is preferred when an extra non-active one exists" do
    partner = Partner.create!(name: "Test", code: "test_partner")
    # Connexion suspendue plus récente, mais une active existe : l'active doit gagner.
    create_partner_connection!(
      partner: partner, inbound_token: "old-secret",
      status: "suspended", remote_url: "http://old.example.com"
    )
    active = create_partner_connection!(
      partner: partner, inbound_token: "secret-inbound",
      status: "active", remote_url: "http://current.example.com"
    )

    headers = signed_headers(connection: active, method: "GET", path: "/api/v1/products")

    get "/api/v1/products", headers: headers
    assert_response :success
  end
end
