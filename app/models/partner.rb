class Partner < ApplicationRecord
  has_secure_token :auth_token
  has_many :identifier_pairs

  def self.main_partner
    find_by(code: "circle")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "auth_token", "code", "created_at", "id", "id_value", "name", "updated_at" ]
  end
end
