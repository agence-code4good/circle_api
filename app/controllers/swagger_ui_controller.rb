class SwaggerUiController < ApplicationController
  # Skip authentication and authorization for public API docs
  skip_before_action :authenticate_user!
  skip_after_action :verify_authorized

  def index
    @config_object = {
      url: "/openapi/api.yaml",
      dom_id: "#swagger-ui",
      validatorUrl: nil
    }
    render layout: "application"
  end
end
