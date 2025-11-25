# app/services/validations/product_validation.rb
require_relative "base_validation"

module Validations
  class ProductValidation < BaseValidation
    def initialize(code, value, rule, version, circle_values)
      super(code, value, rule, version, circle_values)
      @product = find_product
    end

    def validate
      return if @product.nil?
      vintage = circle_values.dig("C11")
      return nil unless vintage

      starting_vintage = @product.starting_vintage.value
      late_vintage = @product.late_vintage.value

      if @product.excluded_vintages.pluck(:value).include?(vintage) ||
        (starting_vintage != "ND" && vintage < starting_vintage) ||
        (late_vintage != "ND" && vintage > late_vintage) ||
        (vintage > Date.today.year.to_s)
       return "Le millésime #{vintage} n'existe pas pour le produit #{@product.value}."
      end
    end

    def default_error_message(code)
      "Erreur product_validation sur #{code}."
    end

  end
end
