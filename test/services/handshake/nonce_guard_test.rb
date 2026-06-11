# frozen_string_literal: true

require "test_helper"

class Handshake::NonceGuardTest < ActiveSupport::TestCase
  include HandshakeTestHelper

  setup do
    @partner = Partner.create!(name: "Guard", code: "guard")
    @connection = create_partner_connection!(partner: @partner, inbound_token: "secret")
  end

  test "consumes a fresh nonce once" do
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(connection: @connection, nonce: nonce, purpose: "request")
  end

  test "rejects a replayed nonce for the same connection" do
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(connection: @connection, nonce: nonce, purpose: "request")
    refute Handshake::NonceGuard.consume(connection: @connection, nonce: nonce, purpose: "request")
  end

  test "same nonce is allowed across different connections" do
    other = create_partner_connection!(
      partner: @partner,
      inbound_token: "secret2",
      remote_url: "http://other.example.com",
      status: "pending"
    )
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(connection: @connection, nonce: nonce, purpose: "request")
    assert Handshake::NonceGuard.consume(connection: other, nonce: nonce, purpose: "request")
  end

  test "rejects blank nonce" do
    refute Handshake::NonceGuard.consume(connection: @connection, nonce: "", purpose: "request")
  end

  test "prune_expired removes only expired rows" do
    HandshakeNonce.create!(partner_connection: @connection, nonce: "old", purpose: "request", expires_at: 1.hour.ago)
    HandshakeNonce.create!(partner_connection: @connection, nonce: "fresh", purpose: "request", expires_at: 1.hour.from_now)

    Handshake::NonceGuard.prune_expired

    assert_nil HandshakeNonce.find_by(nonce: "old")
    assert HandshakeNonce.find_by(nonce: "fresh")
  end
end
