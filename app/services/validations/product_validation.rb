# app/services/validations/product_validation.rb
require_relative "base_validation"

module Validations
  class ProductValidation < BaseValidation
    def initialize(code, value, rule, version, circle_values)
      super(code, value, rule, version, circle_values)
      @product = find_product
    end

    def validate
      if @product.nil?
        return "Le produit #{value} n'existe pas."
      end
      vintage = circle_values.dig("C11")

      unless @product.vintage_allowed?(vintage)
       "Le millésime #{vintage} n'existe pas pour le produit #{@product.code}."
      end
    end

    def default_error_message(code)
      "Erreur product_validation sur #{code}."
    end
  end
end
