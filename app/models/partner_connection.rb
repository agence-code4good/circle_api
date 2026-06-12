# frozen_string_literal: true

class PartnerConnection < ApplicationRecord
  STATUSES = %w[pending active suspended key_mismatch].freeze

  belongs_to :partner
  has_many :handshake_nonces, dependent: :delete_all

  encrypts :inbound_token
  encrypts :outbound_token

  attr_accessor :inbound_token_for_set, :outbound_token_for_set, :generated_inbound_token

  before_validation :apply_tokens_for_set
  before_validation :generate_inbound_token_if_needed, on: :create
  before_validation :normalize_remote_base_url

  validates :remote_base_url, presence: true, uniqueness: { scope: :partner_id }
  validates :status, inclusion: { in: STATUSES }
  validates :handshake_version, inclusion: { in: [ 2 ] }
  validate :remote_base_url_must_be_https, if: -> { remote_base_url.present? }
  validate :only_one_active_per_partner, if: -> { status == "active" }

  scope :active, -> { where(status: "active") }
  scope :for_partner_code, ->(code) { joins(:partner).where(partners: { code: code }) }

  def verify_inbound_token?(plain_token)
    return false if inbound_token.blank? || plain_token.blank?

    Handshake::Crypto.secure_compare(inbound_token, plain_token)
  end

  def mutual_challenge_complete?
    inbound_challenge_verified_at.present? && outbound_challenge_verified_at.present?
  end

  def activate_if_ready!
    return unless mutual_challenge_complete?
    return if pinned_public_key.blank?

    update!(status: "active", last_challenge_at: Time.current)
  end

  def suspend!(reason: nil)
    update!(status: "suspended")
    Rails.logger.warn("[Handshake] Connection #{id} suspended: #{reason}")
  end

  def mark_key_mismatch!
    update!(status: "key_mismatch")
  end

  def pin_public_key!(public_key)
    key_changed = pinned_public_key.present? && pinned_public_key != public_key
    attrs = {
      pinned_public_key: public_key,
      pinned_public_key_fingerprint: Handshake::Crypto.fingerprint(public_key)
    }
    if key_changed
      attrs[:inbound_challenge_verified_at] = nil
      attrs[:outbound_challenge_verified_at] = nil
      attrs[:status] = "pending"
    elsif status == "key_mismatch"
      attrs[:status] = "pending"
    end
    update!(attrs)
  end

  def touch_successful_exchange!
    update!(last_successful_exchange_at: Time.current)
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      created_at handshake_version id inbound_challenge_verified_at
      last_challenge_at last_successful_exchange_at linkage_code_local
      linkage_code_remote outbound_challenge_verified_at partner_id
      pinned_public_key_fingerprint remote_base_url status updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[partner]
  end

  private

  def generate_inbound_token_if_needed
    return if inbound_token.present? || inbound_token_for_set.present?

    token = Handshake::TokenGenerator.generate
    self.inbound_token_for_set = token
    self.generated_inbound_token = token
  end

  def apply_tokens_for_set
    if inbound_token_for_set.present? && inbound_token.blank?
      self.inbound_token = inbound_token_for_set
      self.generated_inbound_token = inbound_token_for_set
    end

    if outbound_token_for_set.present?
      self.outbound_token = outbound_token_for_set
    end
  end

  def normalize_remote_base_url
    return if remote_base_url.blank?

    self.remote_base_url = remote_base_url.to_s.strip.chomp("/")
  end

  def remote_base_url_must_be_https
    uri = URI.parse(remote_base_url)
    return if (Rails.env.development? || Rails.env.test?) && uri.scheme == "http"

    errors.add(:remote_base_url, "doit utiliser HTTPS") unless uri.scheme == "https"
  rescue URI::InvalidURIError
    errors.add(:remote_base_url, "n'est pas une URL valide")
  end

  def only_one_active_per_partner
    existing = PartnerConnection.where(partner_id: partner_id, status: "active")
    existing = existing.where.not(id: id) if persisted?
    errors.add(:status, "une seule connexion active par partenaire") if existing.exists?
  end

end
