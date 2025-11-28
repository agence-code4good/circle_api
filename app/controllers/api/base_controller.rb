class Api::BaseController < ActionController::API
  # Désactive la protection CSRF pour les endpoints API

  private

  def authenticate_partner!
    token = request.headers["Authorization"].to_s.remove("Bearer ")
    @current_partner = Partner.find_by(auth_token: token)
    head :unauthorized unless @current_partner
  end
end
