# app/models/circle_product.rb
class CircleProduct < ApplicationRecord
  has_many :circle_codes, dependent: :destroy

  accepts_nested_attributes_for :circle_codes
  validates :circle_codes, presence: true

  # Recherche par codes partiels pour l'api search_circle_values
  def self.find_by_input_codes(input_codes)
    # Trouve un produit qui matche TOUS les codes donnés
    product_ids = nil

    input_codes.each do |code, value|
      matching_ids = CircleCode.where(code: code, value: value.to_s)
                               .pluck(:circle_product_id)
                               .uniq

      product_ids = product_ids ? (product_ids & matching_ids) : matching_ids
    end

    CircleProduct.find(product_ids.first) if product_ids&.any?
  end

  # Récupérer un code spécifique
  def get_code_value(code)
    circle_codes.find_by(code: code)&.value
  end

  # Récupérer plusieurs codes
  def get_codes(code_list)
    circle_codes.where(code: code_list).pluck(:code, :value).to_h
  end
end
