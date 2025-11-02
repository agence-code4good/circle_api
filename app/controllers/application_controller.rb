class ApplicationController < ActionController::Base
  before_action :authenticate_user!
  include Pundit::Authorization
  rescue_from Pundit::NotAuthorizedError, with: :user_not_authorized
  after_action :verify_authorized, unless: :skip_pundit?

  def active_admin_controller?
    is_a?(ActiveAdmin::BaseController)
  end

  def skip_pundit?
    devise_controller? || params[:controller] =~ /(^(rails_)?admin)|(^pages$)/ || active_admin_controller?
  end

  def user_not_authorized
    flash[:alert] = "Vous n'êtes pas autorisé à réaliser cette action."
    redirect_to(root_path)
  end
end
