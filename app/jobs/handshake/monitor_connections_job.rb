# frozen_string_literal: true

module Handshake
  class MonitorConnectionsJob < ApplicationJob
    queue_as :default

    def perform
      NonceGuard.prune_expired

      Partner.where(handshake_status: "active").find_each do |partner|
        FetchIdentity.new(partner).call
      rescue FetchIdentity::FetchError => e
        Rails.logger.warn("[Handshake::Monitor] partner=#{partner.id} #{e.message}")
      end
    end
  end
end
