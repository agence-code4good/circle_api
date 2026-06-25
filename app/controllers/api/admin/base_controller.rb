# frozen_string_literal: true

class Api::Admin::BaseController < ActionController::API
  include HandshakeIdentityImportAuthenticatable

  before_action :authenticate_identity_import!
end
