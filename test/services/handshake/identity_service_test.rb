# frozen_string_literal: true

require "test_helper"

class Handshake::IdentityServiceTest < ActiveSupport::TestCase
  setup do
    InstanceIdentity.delete_all
  end

  test "import! stores a valid keypair" do
    keypair = Handshake::Crypto.generate_keypair

    identity = Handshake::IdentityService.import!(
      public_key: keypair[:public_key],
      private_key: keypair[:private_key],
      key_version: 1
    )

    assert_equal 1, identity.key_version
    assert_equal keypair[:public_key], Handshake::IdentityService.current.public_key
  end

  test "import! rejects mismatched keys" do
    keypair = Handshake::Crypto.generate_keypair
    other = Handshake::Crypto.generate_keypair

    error = assert_raises(Handshake::IdentityService::ImportError) do
      Handshake::IdentityService.import!(
        public_key: keypair[:public_key],
        private_key: other[:private_key],
        key_version: 1
      )
    end

    assert_match(/invalide/, error.message)
  end

  test "import! requires higher key_version for rotation" do
    keypair = Handshake::Crypto.generate_keypair
    Handshake::IdentityService.import!(
      public_key: keypair[:public_key],
      private_key: keypair[:private_key],
      key_version: 1
    )

    assert_raises(Handshake::IdentityService::ImportError) do
      Handshake::IdentityService.import!(
        public_key: keypair[:public_key],
        private_key: keypair[:private_key],
        key_version: 1
      )
    end

    rotated = Handshake::Crypto.generate_keypair
    identity = Handshake::IdentityService.import!(
      public_key: rotated[:public_key],
      private_key: rotated[:private_key],
      key_version: 2
    )

    assert_equal 2, identity.key_version
    assert_equal rotated[:public_key], Handshake::IdentityService.current.public_key
  end

  test "require! raises when identity is missing" do
    assert_raises(Handshake::IdentityService::MissingIdentityError) do
      Handshake::IdentityService.require!
    end
  end

  test "generate_for_dev! creates identity in test environment" do
    identity = Handshake::IdentityService.generate_for_dev!

    assert identity.present?
    assert_equal 1, identity.key_version
  end
end
