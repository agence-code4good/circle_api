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
end
