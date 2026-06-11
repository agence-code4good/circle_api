# frozen_string_literal: true

module HandshakeAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_partner!
    partner_code = request.headers["X-Partner-Code"].to_s.strip
    token = bearer_token

    if token.blank? || partner_code.blank?
      render_handshake_error(:unauthorized, "unauthorized")
      return
    end

    @current_connection = Handshake::ConnectionResolver.for_incoming(partner_code: partner_code)

    unless @current_connection
      render_handshake_error(:unauthorized, "unauthorized")
      return
    end

    unless @current_connection.verify_inbound_token?(token)
      render_handshake_error(:unauthorized, "unauthorized")
      return
    end

    unless connection_allows_exchange?(@current_connection)
      return
    end

    unless verify_request_signature!
      render_handshake_error(:unauthorized, "invalid_signature")
      return
    end

    unless Handshake::NonceGuard.consume(
      connection: @current_connection,
      nonce: request.headers["X-Handshake-Nonce"].to_s,
      purpose: "request"
    )
      render_handshake_error(:unauthorized, "nonce_replayed")
      return
    end

    @current_partner = @current_connection.partner
    @current_connection.touch_successful_exchange!
  end

  def bearer_token
    request.headers["Authorization"].to_s.remove("Bearer").strip
  end

  def connection_allows_exchange?(connection)
    case connection.status
    when "active"
      true
    when "key_mismatch"
      render_handshake_error(:forbidden, "key_mismatch")
      false
    when "suspended"
      render_handshake_error(:forbidden, "connection_suspended")
      false
    else
      render_handshake_error(:forbidden, "connection_not_active")
      false
    end
  end

  def verify_request_signature!
    nonce = request.headers["X-Handshake-Nonce"].to_s
    timestamp = request.headers["X-Handshake-Timestamp"].to_s
    signature = request.headers["X-Handshake-Signature"].to_s

    return false if nonce.blank? || timestamp.blank? || signature.blank?
    return false if @current_connection.pinned_public_key.blank?

    body = request.body&.read.to_s
    request.body&.rewind

    Handshake::Signing.verify_request(
      public_key_b64: @current_connection.pinned_public_key,
      method: request.method,
      path: request.path,
      body: body,
      nonce: nonce,
      timestamp: timestamp,
      signature_b64: signature
    )
  end

  def render_handshake_error(status, error_code)
    render json: { error: error_code }, status: status
  end
end
