# frozen_string_literal: true

module HandshakeIdentityImportAuthenticatable
  extend ActiveSupport::Concern

  private

  def authenticate_identity_import!
    configured = Rails.application.config.handshake_identity_import_token

    if configured.blank?
      render json: { error: "identity_import_not_configured" }, status: :service_unavailable
      return
    end

    token = bearer_token
    return if token.present? && ActiveSupport::SecurityUtils.secure_compare(token, configured)

    render json: { error: "unauthorized" }, status: :unauthorized
  end

  def bearer_token
    request.headers["Authorization"].to_s.remove("Bearer").strip
  end
end
