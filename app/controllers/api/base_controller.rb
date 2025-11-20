class Api::BaseController < ActionController::API
  # Désactive la protection CSRF pour les endpoints API
  # car les APIs utilisent généralement l'authentification par token
end
