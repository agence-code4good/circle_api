# frozen_string_literal: true

class Partner < ApplicationRecord
  HANDSHAKE_STATUSES = %w[pending active suspended key_mismatch].freeze

  has_many :users, dependent: :nullify
  has_many :partner_aliases, dependent: :destroy
  has_many :handshake_nonces, dependent: :delete_all

  attr_accessor :auth_token_for_set, :generated_auth_token, :pinned_public_key_for_set

  before_validation :apply_auth_token_for_set
  before_validation :apply_pinned_public_key_for_set
  before_validation :generate_auth_token_if_needed, on: :create
  before_validation :normalize_remote_base_url

  validates :code, presence: true, uniqueness: true
  validates :name, presence: true
  validates :remote_base_url, presence: true
  validates :handshake_status, inclusion: { in: HANDSHAKE_STATUSES }
  validates :handshake_version, inclusion: { in: [ 2 ] }
  validate :remote_base_url_must_be_https, if: -> { remote_base_url.present? }

  def self.main_partner
    find_by(code: "circle")
  end

  def verify_auth_token?(plain_token)
    return false if auth_token_digest.blank? || plain_token.blank?

    BCrypt::Password.new(auth_token_digest).is_password?(plain_token)
  rescue BCrypt::Errors::InvalidHash
    false
  end

  def mutual_challenge_complete?
    inbound_challenge_verified_at.present? && outbound_challenge_verified_at.present?
  end

  def activate_if_ready!
    return unless mutual_challenge_complete?
    return if pinned_public_key.blank?

    update!(handshake_status: "active", last_challenge_at: Time.current)
  end

  def suspend!(reason: nil)
    update!(handshake_status: "suspended")
    Rails.logger.warn("[Handshake] Partner #{id} (#{code}) suspended: #{reason}")
  end

  def mark_key_mismatch!
    update!(handshake_status: "key_mismatch")
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
      attrs[:handshake_status] = "pending"
    elsif handshake_status == "key_mismatch"
      attrs[:handshake_status] = "pending"
    end
    update!(attrs)
  end

  def record_outbound_challenge!
    update!(
      outbound_challenge_verified_at: Time.current,
      last_challenge_at: Time.current
    )
    activate_if_ready!
  end

  def touch_successful_exchange!
    update!(last_successful_exchange_at: Time.current)
  end

  def outbound_partner_code
    linkage_code_remote.presence || Rails.application.config.handshake_instance_code
  end

  def self.ransackable_attributes(_auth_object = nil)
    %w[
      code created_at handshake_status id id_value linkage_code_remote name
      pinned_public_key_fingerprint remote_base_url updated_at
    ]
  end

  def self.ransackable_associations(_auth_object = nil)
    %w[partner_aliases users]
  end

  private

  def set_auth_token(plain_token)
    return if plain_token.blank?

    self.auth_token_digest = BCrypt::Password.create(plain_token)
  end

  def apply_auth_token_for_set
    return if auth_token_for_set.blank?

    set_auth_token(auth_token_for_set)
    self.generated_auth_token = auth_token_for_set
  end

  def apply_pinned_public_key_for_set
    return if pinned_public_key_for_set.blank?

    self.pinned_public_key = pinned_public_key_for_set
    self.pinned_public_key_fingerprint = Handshake::Crypto.fingerprint(pinned_public_key_for_set)
  end

  def generate_auth_token_if_needed
    return if auth_token_digest.present? || auth_token_for_set.present?

    token = Handshake::TokenGenerator.generate
    self.auth_token_for_set = token
    self.generated_auth_token = token
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
end
