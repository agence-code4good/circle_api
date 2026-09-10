# frozen_string_literal: true

require "test_helper"

class Handshake::CryptoTest < ActiveSupport::TestCase
  test "generate sign and verify round trip" do
    keypair = Handshake::Crypto.generate_keypair
    message = "test-message"
    signature = Handshake::Crypto.sign(keypair[:private_key], message)

    assert Handshake::Crypto.verify(keypair[:public_key], signature, message)
    assert_not Handshake::Crypto.verify(keypair[:public_key], signature, "tampered")
  end

  test "fingerprint is stable" do
    keypair = Handshake::Crypto.generate_keypair
    fp1 = Handshake::Crypto.fingerprint(keypair[:public_key])
    fp2 = Handshake::Crypto.fingerprint(keypair[:public_key])
    assert_equal fp1, fp2
  end
end
