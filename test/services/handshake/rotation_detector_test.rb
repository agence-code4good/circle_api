# frozen_string_literal: true

require "test_helper"

class Handshake::RotationDetectorTest < ActiveSupport::TestCase
  test "marks key_mismatch when remote identity diverges from pinned key" do
    old_key = Handshake::Crypto.generate_keypair
    new_key = Handshake::Crypto.generate_keypair

    partner = Partner.create!(
      name: "Remote",
      code: "remote",
      remote_base_url: "http://example.com",
      auth_token_for_set: "token",
      pinned_public_key: old_key[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(old_key[:public_key]),
      handshake_status: "active"
    )

    stub_remote_identity_fetch(public_key: new_key[:public_key], key_version: 2, algorithm: "Ed25519") do
      assert Handshake::RotationDetector.call(partner)
    end

    assert_equal "key_mismatch", partner.reload.handshake_status
  end

  test "returns false when remote identity matches pinned key" do
    keypair = Handshake::Crypto.generate_keypair

    partner = Partner.create!(
      name: "Remote",
      code: "remote",
      remote_base_url: "http://example.com",
      auth_token_for_set: "token",
      pinned_public_key: keypair[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(keypair[:public_key]),
      handshake_status: "active"
    )

    stub_remote_identity_fetch(public_key: keypair[:public_key], key_version: 1, algorithm: "Ed25519") do
      assert_not Handshake::RotationDetector.call(partner)
    end

    assert_equal "active", partner.reload.handshake_status
  end

  test "returns false when identity fetch fails" do
    keypair = Handshake::Crypto.generate_keypair

    partner = Partner.create!(
      name: "Remote",
      code: "remote",
      remote_base_url: "http://example.com",
      auth_token_for_set: "token",
      pinned_public_key: keypair[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(keypair[:public_key]),
      handshake_status: "active"
    )

    stub_remote_identity_fetch(Handshake::RemoteIdentity::FetchError.new("HTTP 503")) do
      assert_not Handshake::RotationDetector.call(partner)
    end

    assert_equal "active", partner.reload.handshake_status
  end
end
