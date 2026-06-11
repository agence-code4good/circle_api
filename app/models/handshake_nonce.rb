# frozen_string_literal: true

class HandshakeNonce < ApplicationRecord
  PURPOSES = %w[request challenge].freeze

  belongs_to :partner_connection

  validates :nonce, presence: true
  validates :purpose, inclusion: { in: PURPOSES }
  validates :expires_at, presence: true

  scope :expired, -> { where(expires_at: ..Time.current) }
end
