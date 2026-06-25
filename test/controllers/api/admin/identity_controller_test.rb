# frozen_string_literal: true

require "test_helper"

class Api::Admin::IdentityControllerTest < ActionDispatch::IntegrationTest
  setup do
    InstanceIdentity.delete_all
  end

  test "create imports identity with valid token" do
    keypair = Handshake::Crypto.generate_keypair

    post "/api/admin/identity",
         params: {
           public_key: keypair[:public_key],
           private_key: keypair[:private_key],
           key_version: 1
         },
         headers: { "Authorization" => "Bearer test-import-token" },
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal "Ed25519", body["algorithm"]
    assert_equal keypair[:public_key], body["public_key"]
    assert_equal 1, body["key_version"]
  end

  test "create accepts nested identity params" do
    keypair = Handshake::Crypto.generate_keypair

    post "/api/admin/identity",
         params: {
           identity: {
             public_key: keypair[:public_key],
             private_key: keypair[:private_key]
           }
         },
         headers: { "Authorization" => "Bearer test-import-token" },
         as: :json

    assert_response :created
  end

  test "create rotates identity with higher key_version" do
    first = Handshake::Crypto.generate_keypair
    second = Handshake::Crypto.generate_keypair
    headers = { "Authorization" => "Bearer test-import-token" }

    post "/api/admin/identity",
         params: { public_key: first[:public_key], private_key: first[:private_key], key_version: 1 },
         headers: headers,
         as: :json
    assert_response :created

    post "/api/admin/identity",
         params: { public_key: second[:public_key], private_key: second[:private_key], key_version: 2 },
         headers: headers,
         as: :json

    assert_response :created
    body = JSON.parse(response.body)
    assert_equal 2, body["key_version"]
    assert_equal second[:public_key], Handshake::IdentityService.current.public_key
  end

  test "create rejects invalid keypair" do
    first = Handshake::Crypto.generate_keypair
    second = Handshake::Crypto.generate_keypair

    post "/api/admin/identity",
         params: {
           public_key: first[:public_key],
           private_key: second[:private_key],
           key_version: 1
         },
         headers: { "Authorization" => "Bearer test-import-token" },
         as: :json

    assert_response :unprocessable_entity
  end

  test "create requires bearer token" do
    keypair = Handshake::Crypto.generate_keypair

    post "/api/admin/identity",
         params: { public_key: keypair[:public_key], private_key: keypair[:private_key] },
         as: :json

    assert_response :unauthorized
  end

  test "create returns service unavailable when import token not configured" do
    Rails.application.config.handshake_identity_import_token = nil
    keypair = Handshake::Crypto.generate_keypair

    post "/api/admin/identity",
         params: { public_key: keypair[:public_key], private_key: keypair[:private_key] },
         headers: { "Authorization" => "Bearer test-import-token" },
         as: :json

    assert_response :service_unavailable
  ensure
    Rails.application.config.handshake_identity_import_token = "test-import-token"
  end
end
