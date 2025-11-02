# frozen_string_literal: true

class Users::SessionsController < Devise::SessionsController
  # prepend_before_action :check_captcha, only: [:create]
  # before_action :configure_sign_in_params, only: [:create]

  # GET /resource/sign_in
  # def new
  #   super
  # end

  # POST /resource/sign_in
  def create
    super
  end

  # DELETE /resource/sign_out
  # def destroy
  #   super
  # end

  # protected

  # If you have extra params to permit, append them to the sanitizer.
  # def configure_sign_in_params
  #   devise_parameter_sanitizer.permit(:sign_in, keys: [:attribute])
  # end

  private

  def check_captcha
    # Ajouter les keys quand elles auront été générées
    unless verify_recaptcha(secret_key: ENV["RECAPTCHA_SECRET_KEY"] )
      self.resource = resource_class.new sign_in_params
      respond_with_navigational(resource) do
        flash[:alert] = "La création de votre compte n’a pas pu être réalisée. Vous avez été identifié comme un bot." # à ajouter dans I18n
        render :new
      end
    end
  end
end
