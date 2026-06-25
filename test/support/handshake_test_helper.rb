# frozen_string_literal: true

module HandshakeTestHelper
  def setup_handshake_identity!
    return if Handshake::IdentityService.current.present?

    keypair = Handshake::Crypto.generate_keypair
    Handshake::IdentityService.import!(
      public_key: keypair[:public_key],
      private_key: keypair[:private_key],
      key_version: 1
    )
  end

  def create_handshake_partner!(
    code:,
    name: nil,
    auth_token: "secret-inbound",
    handshake_status: "active",
    remote_url: "http://localhost:3000"
  )
    peer_keypair = Handshake::Crypto.generate_keypair
    partner = Partner.create!(
      name: name || code,
      code: code,
      remote_base_url: remote_url,
      auth_token_for_set: auth_token,
      pinned_public_key: peer_keypair[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keypair[:public_key]),
      handshake_status: handshake_status,
      inbound_challenge_verified_at: Time.current,
      outbound_challenge_verified_at: Time.current
    )
    partner.tap do |p|
      p.define_singleton_method(:peer_private_key) { peer_keypair[:private_key] }
      p.define_singleton_method(:auth_token_plain) { auth_token }
    end
  end

  def signed_headers(partner:, method:, path:, body: "", partner_code: nil)
    nonce = SecureRandom.uuid
    timestamp = Time.now.to_i.to_s
    signature = Handshake::Signing.sign_request(
      private_key_b64: partner.peer_private_key,
      method: method,
      path: path,
      body: body,
      nonce: nonce,
      timestamp: timestamp
    )

    {
      "Authorization" => "Bearer #{partner.auth_token_plain}",
      "X-Partner-Code" => partner_code || partner.code,
      "X-Handshake-Nonce" => nonce,
      "X-Handshake-Timestamp" => timestamp,
      "X-Handshake-Signature" => signature
    }
  end

  def stub_remote_identity_fetch(result)
    original = Handshake::RemoteIdentity.method(:fetch)
    Handshake::RemoteIdentity.define_singleton_method(:fetch) do |_partner|
      raise result if result.is_a?(Handshake::RemoteIdentity::FetchError)

      result
    end
    yield
  ensure
    Handshake::RemoteIdentity.define_singleton_method(:fetch, original)
  end
end
