class Api::BaseController < ActionController::API
  include ApiLoggable
  include HandshakeAuthenticatable

  before_action :authenticate_partner!
end
