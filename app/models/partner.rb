class Partner < ApplicationRecord
  has_secure_token :auth_token
  has_many :identifier_pairs

  def self.main_partner
    find_by(code: "circle")
  end
end
