# frozen_string_literal: true

class Api::Admin::IdentityController < Api::Admin::BaseController
  def create
    identity = Handshake::IdentityService.import!(
      public_key: identity_params[:public_key],
      private_key: identity_params[:private_key],
      key_version: identity_params.fetch(:key_version, 1).to_i
    )

    render json: Handshake::IdentityService.public_payload(identity), status: :created
  rescue Handshake::IdentityService::ImportError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def identity_params
    source = params[:identity].presence || params
    source.permit(:public_key, :private_key, :key_version)
  end
end
