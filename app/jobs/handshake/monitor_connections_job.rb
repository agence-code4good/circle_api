# frozen_string_literal: true

module Handshake
  class MonitorConnectionsJob < ApplicationJob
    queue_as :default

    def perform
      PartnerConnection.where(status: "active").find_each do |connection|
        FetchIdentity.new(connection).call
      rescue FetchIdentity::FetchError => e
        Rails.logger.warn("[Handshake::Monitor] connection=#{connection.id} #{e.message}")
      end
    end
  end
end
