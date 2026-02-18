class Api::BaseController < ActionController::API
  include ApiLoggable

  # Désactive la protection CSRF pour les endpoints API

  private

  def authenticate_partner!
    raw_auth_header = request.headers["Authorization"].to_s
    token = raw_auth_header.remove("Bearer").strip
    partner_code = request.headers["X-Partner-Code"].to_s.strip

    if token.blank? || partner_code.blank?
      head :unauthorized
      return
    end

    partner = Partner.find_by(code: partner_code)

    unless partner&.auth_token_digest.present?
      head :unauthorized
      return
    end

    begin
      if BCrypt::Password.new(partner.auth_token_digest).is_password?(token)
        @current_partner = partner
      else
        head :unauthorized
      end
    rescue BCrypt::Errors::InvalidHash
      head :unauthorized
    end
  end
end
