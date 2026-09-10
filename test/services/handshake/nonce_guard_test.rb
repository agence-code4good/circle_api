# frozen_string_literal: true

require "test_helper"

class Handshake::NonceGuardTest < ActiveSupport::TestCase
  setup do
    @partner = create_handshake_partner!(code: "guard")
  end

  test "consumes a fresh nonce once" do
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(partner: @partner, nonce: nonce, purpose: "request")
  end

  test "rejects a replayed nonce for the same partner" do
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(partner: @partner, nonce: nonce, purpose: "request")
    refute Handshake::NonceGuard.consume(partner: @partner, nonce: nonce, purpose: "request")
  end

  test "same nonce is allowed across different partners" do
    other = create_handshake_partner!(code: "other", remote_url: "http://other.example.com")
    nonce = SecureRandom.uuid
    assert Handshake::NonceGuard.consume(partner: @partner, nonce: nonce, purpose: "request")
    assert Handshake::NonceGuard.consume(partner: other, nonce: nonce, purpose: "request")
  end

  test "rejects blank nonce" do
    refute Handshake::NonceGuard.consume(partner: @partner, nonce: "", purpose: "request")
  end

  test "prune_expired removes only expired rows" do
    HandshakeNonce.create!(partner: @partner, nonce: "old", purpose: "request", expires_at: 1.hour.ago)
    HandshakeNonce.create!(partner: @partner, nonce: "fresh", purpose: "request", expires_at: 1.hour.from_now)

    Handshake::NonceGuard.prune_expired

    assert_nil HandshakeNonce.find_by(nonce: "old")
    assert HandshakeNonce.find_by(nonce: "fresh")
  end
end
