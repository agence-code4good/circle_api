class BrokerMandate < ApplicationRecord
  belongs_to :broker_partner, class_name: "Partner"
  belongs_to :buyer_partner, class_name: "Partner"

  validates :broker_partner_id, uniqueness: { scope: :buyer_partner_id }
  validate :ends_at_after_starts_at

  scope :active, -> { where(active: true) }
  scope :active_at, lambda { |time|
    active
      .where("starts_at IS NULL OR starts_at <= ?", time)
      .where("ends_at IS NULL OR ends_at >= ?", time)
  }

  def self.ransackable_associations(auth_object = nil)
    [ "broker_partner", "buyer_partner" ]
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "active", "broker_partner_id", "buyer_partner_id", "created_at", "ends_at", "id", "id_value", "starts_at", "updated_at" ]
  end


  # Vérifie si un mandat courtier est actif pour un couple (broker, buyer).
  # at: instant de référence (Time.current par défaut)
  # broker_code: code du courtier
  # buyer_code: code du buyer
  def self.active_for_codes?(broker_code:, buyer_code:, at: Time.current)
    broker = Partner.find_by(code: broker_code)
    buyer = Partner.find_by(code: buyer_code)
    return false unless broker && buyer

    active_at(at).exists?(broker_partner_id: broker.id, buyer_partner_id: buyer.id)
  end

  private

  def ends_at_after_starts_at
    return if starts_at.blank? || ends_at.blank?
    return if ends_at >= starts_at

    errors.add(:ends_at, "doit être postérieur à starts_at")
  end
end
