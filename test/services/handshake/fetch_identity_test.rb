# frozen_string_literal: true

require "test_helper"

class Handshake::FetchIdentityPinTest < ActiveSupport::TestCase
  test "pin_public_key resets challenges when key changes" do
    partner = Partner.create!(name: "Remote", code: "remote")
    old_key = Handshake::Crypto.generate_keypair
    new_key = Handshake::Crypto.generate_keypair

    connection = PartnerConnection.create!(
      partner: partner,
      remote_base_url: "http://example.com",
      inbound_token: "token",
      pinned_public_key: old_key[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(old_key[:public_key]),
      status: "active",
      inbound_challenge_verified_at: 1.hour.ago,
      outbound_challenge_verified_at: 1.hour.ago
    )

    connection.pin_public_key!(new_key[:public_key])
    connection.reload

    assert_equal "pending", connection.status
    assert_nil connection.inbound_challenge_verified_at
    assert_nil connection.outbound_challenge_verified_at
  end

  test "mark_key_mismatch sets status" do
    partner = Partner.create!(name: "Remote", code: "remote")
    connection = PartnerConnection.create!(
      partner: partner,
      remote_base_url: "http://example.com",
      inbound_token: "token",
      status: "active"
    )

    connection.mark_key_mismatch!
    assert_equal "key_mismatch", connection.reload.status
  end
end
