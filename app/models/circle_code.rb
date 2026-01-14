class CircleCode < ApplicationRecord
  belongs_to :circle_product

  validates :code, presence: true
  validates :value, presence: true
  validates :code, uniqueness: { scope: :circle_product_id }
end
