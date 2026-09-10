# frozen_string_literal: true

require "test_helper"

class Handshake::FetchIdentityPinTest < ActiveSupport::TestCase
  test "pin_public_key resets inbound challenge when key changes" do
    old_key = Handshake::Crypto.generate_keypair
    new_key = Handshake::Crypto.generate_keypair

    partner = Partner.create!(
      name: "Remote",
      code: "remote",
      remote_base_url: "http://example.com",
      auth_token_for_set: "token",
      pinned_public_key: old_key[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(old_key[:public_key]),
      handshake_status: "active",
      inbound_challenge_verified_at: 1.hour.ago
    )

    partner.pin_public_key!(new_key[:public_key])
    partner.reload

    assert_equal "pending", partner.handshake_status
    assert_nil partner.inbound_challenge_verified_at
  end

  test "mark_key_mismatch sets status" do
    partner = Partner.create!(
      name: "Remote",
      code: "remote",
      remote_base_url: "http://example.com",
      auth_token_for_set: "token",
      handshake_status: "active"
    )

    partner.mark_key_mismatch!
    assert_equal "key_mismatch", partner.reload.handshake_status
  end
end
