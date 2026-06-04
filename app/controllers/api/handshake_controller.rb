# frozen_string_literal: true

class Api::HandshakeController < ActionController::API
  include ApiLoggable

  skip_around_action :log_api_request, only: %i[identity challenge]

  def identity
    Handshake::IdentityService.ensure!
    render json: Handshake::IdentityService.public_payload
  end

  def challenge
    partner_code = request.headers["X-Partner-Code"].to_s.strip
    token = bearer_token

    if token.blank? || partner_code.blank?
      return render json: { error: "unauthorized" }, status: :unauthorized
    end

    connection = Handshake::ConnectionResolver.for_incoming(partner_code: partner_code)

    unless connection&.verify_inbound_token?(token)
      return render json: { error: "unauthorized" }, status: :unauthorized
    end

    if connection.status == "suspended"
      return render json: { error: "connection_suspended" }, status: :forbidden
    end

    if connection.status == "key_mismatch"
      return render json: { error: "key_mismatch" }, status: :forbidden
    end

    payload = challenge_params
    result = Handshake::Challenge.new(
      connection: connection,
      nonce: payload[:nonce],
      signature: payload[:signature]
    ).call

    log_handshake_event(connection, "challenge_inbound", success: true)
    render json: result
  rescue Handshake::Challenge::ChallengeError => e
    log_handshake_event(connection, "challenge_inbound", success: false, error: e.code)
    render json: { error: e.code }, status: challenge_error_status(e.code)
  end

  private

  def bearer_token
    request.headers["Authorization"].to_s.remove("Bearer").strip
  end

  def challenge_params
    body = request.body.read
    request.body.rewind
    parsed = JSON.parse(body)
    { nonce: parsed["nonce"], signature: parsed["signature"] }
  rescue JSON::ParserError
    { nonce: nil, signature: nil }
  end

  def challenge_error_status(code)
    case code
    when "connection_suspended", "key_mismatch" then :forbidden
    when "missing_nonce" then :unprocessable_entity
    else :unauthorized
    end
  end

  def log_handshake_event(connection, event, success:, error: nil)
    return unless connection

    ApiLog.create(
      request_id: request.request_id,
      partner: connection.partner,
      partner_connection_id: connection.id,
      handshake_event: event,
      http_method: request.method,
      endpoint: request.path,
      path: request.fullpath,
      ip_address: request.remote_ip,
      user_agent: request.user_agent,
      request_headers: { x_partner_code: request.headers["X-Partner-Code"] },
      status_code: success ? 200 : 401,
      validation_success: success,
      validation_errors: error ? { error: error } : nil
    )
  rescue StandardError => e
    Rails.logger.error("Handshake log failed: #{e.message}")
  end
end
