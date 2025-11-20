class OrderLine < ApplicationRecord
  belongs_to :order

  validates :circle_code, presence: true

  def total_volume
    circle_code["C2"].to_i
  end
end
