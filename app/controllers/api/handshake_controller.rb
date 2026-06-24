# frozen_string_literal: true

class Api::HandshakeController < ActionController::API
  include ApiLoggable

  skip_around_action :log_api_request, only: %i[identity challenge]

  def identity
    render json: Handshake::IdentityService.public_payload
  rescue Handshake::IdentityService::MissingIdentityError
    render json: { error: "identity_not_configured" }, status: :service_unavailable
  end

  def challenge
    partner_code = request.headers["X-Partner-Code"].to_s.strip
    token = bearer_token

    if token.blank? || partner_code.blank?
      return render json: { error: "unauthorized" }, status: :unauthorized
    end

    partner = Handshake::ConnectionResolver.for_incoming(partner_code: partner_code)

    unless partner&.verify_auth_token?(token)
      return render json: { error: "unauthorized" }, status: :unauthorized
    end

    payload = challenge_params
    result = Handshake::Challenge.new(
      partner: partner,
      nonce: payload[:nonce],
      signature: payload[:signature]
    ).call

    log_handshake_event(partner, "challenge_inbound", success: true)
    render json: result
  rescue Handshake::Challenge::ChallengeError => e
    log_handshake_event(partner, "challenge_inbound", success: false, error: e.code)
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
    when "connection_suspended", "key_mismatch", "missing_public_key" then :forbidden
    when "missing_nonce" then :unprocessable_entity
    else :unauthorized
    end
  end

  def log_handshake_event(partner, event, success:, error: nil)
    return unless partner

    ApiLog.create(
      request_id: request.request_id,
      partner: partner,
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
