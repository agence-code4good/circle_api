# frozen_string_literal: true

module HandshakeTestHelper
  def setup_handshake_identity!
    Handshake::IdentityService.ensure!
  end

  def create_partner_connection!(partner:, inbound_token:, outbound_token: nil, status: "active", remote_url: "http://localhost:3000")
    peer_keypair = Handshake::Crypto.generate_keypair

    PartnerConnection.create!(
      partner: partner,
      remote_base_url: remote_url,
      inbound_token: inbound_token,
      outbound_token: outbound_token || Handshake::TokenGenerator.generate,
      pinned_public_key: peer_keypair[:public_key],
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(peer_keypair[:public_key]),
      status: status,
      inbound_challenge_verified_at: Time.current,
      outbound_challenge_verified_at: Time.current
    ).tap do |conn|
      conn.define_singleton_method(:peer_private_key) { peer_keypair[:private_key] }
    end
  end

  def signed_headers(connection:, method:, path:, body: "", partner_code: nil)
    nonce = SecureRandom.uuid
    timestamp = Time.now.to_i.to_s
    signature = Handshake::Signing.sign_request(
      private_key_b64: connection.peer_private_key,
      method: method,
      path: path,
      body: body,
      nonce: nonce,
      timestamp: timestamp
    )

    {
      "Authorization" => "Bearer #{connection.inbound_token}",
      "X-Partner-Code" => partner_code || connection.partner.code,
      "X-Handshake-Nonce" => nonce,
      "X-Handshake-Timestamp" => timestamp,
      "X-Handshake-Signature" => signature
    }
  end
end
