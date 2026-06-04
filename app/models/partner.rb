class Partner < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :partner_aliases, dependent: :destroy
  has_many :partner_connections, dependent: :destroy

  def self.main_partner
    find_by(code: "circle")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "id", "id_value", "name", "updated_at" ]
  end
end
