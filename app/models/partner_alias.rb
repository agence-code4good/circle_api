class PartnerAlias < ApplicationRecord
  belongs_to :partner

  validates :external_id, presence: true
  validates :partner_code, presence: true
  validates :external_id, uniqueness: { scope: :partner_id }

  validate :partner_code_must_exist

  def self.ransackable_associations(auth_object = nil)
    [ "partner" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "created_at", "external_id", "id", "id_value", "partner_code", "partner_id", "updated_at" ]
  end

  private

  def partner_code_must_exist
    return if partner_code.blank?
    return if Partner.exists?(code: partner_code)

    errors.add(:partner_code, "doit correspondre à un partenaire existant")
  end
end
