Rails.application.routes.draw do
  root to: "admin/dashboard#index"
  get "legal", to: "pages#legal"

  devise_for :admin_users, ActiveAdmin::Devise.config
  ActiveAdmin.routes(self) rescue ActiveAdmin::DatabaseHitDuringLoad
  devise_for :users

  namespace :api, defaults: { format: :json } do
    namespace :v1 do
      # Validation "à blanc" (sans commande associée)
      post "validation", to: "validations#validate"

      # Commandes
      resources :orders, only: [ :create, :update, :show, :index ]

      # Catalogue produits (lecture seule)
      resources :products, only: [ :index, :show ], param: :c10

      # Recherche de circle_values (pour la enrichir les order_lines des commandes)
      post "search_circle_values", to: "circle_values#search"
    end
  end
end
