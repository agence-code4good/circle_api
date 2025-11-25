class IdentifierPair < ApplicationRecord
  belongs_to :partner
  validates :my_alias, presence: true
  validates :partner_alias, presence: true

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "created_at", "id", "id_value", "my_alias", "partner_alias", "partner_id", "updated_at" ]
  end

  def self.ransackable_associations(auth_object = nil)
    [ "partner" ]
  end
end
