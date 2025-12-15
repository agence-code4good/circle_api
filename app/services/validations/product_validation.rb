# app/services/validations/product_validation.rb
require_relative "base_validation"

module Validations
  class ProductValidation < BaseValidation
    def initialize(code, value, rule, version, circle_values)
      super(code, value, rule, version, circle_values)
      @products = find_product
    end

    def validate
      errors = []
      vintage = circle_values.dig("C11")

      @products.each_with_index do |product, index|
        if product.nil?
          errors << "Le produit #{value} n'existe pas."
          next
        end

        current_vintage = vintage.is_a?(Array) ? vintage[index] : vintage

        unless product.vintage_allowed?(current_vintage)
          errors << "Le millésime #{current_vintage} n'existe pas pour le produit #{product.code}."
        end
      end

      return nil if errors.empty?
      errors
    end

    def default_error_message(code)
      "Erreur product_validation sur #{code}."
    end
  end
end
