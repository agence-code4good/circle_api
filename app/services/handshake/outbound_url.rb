# frozen_string_literal: true

module Handshake
  # Réécrit les URL « navigateur » (localhost:3000) en URL joignables depuis le conteneur Docker.
  class OutboundUrl
    def self.resolve(base_url)
      normalized = base_url.to_s.chomp("/")
      return normalized unless rewrite_enabled?

      uri = URI.parse(normalized)
      mapping_for("#{uri.host}:#{uri.port}") || normalized
    rescue URI::InvalidURIError
      normalized
    end

    def self.rewrite_enabled?
      return false unless Rails.env.development? || Rails.env.test?
      return false if ENV["HANDSHAKE_OUTBOUND_REWRITE"] == "false"
      return true if ENV["HANDSHAKE_OUTBOUND_REWRITE"] == "true"

      File.exist?("/.dockerenv")
    end

    def self.mapping_for(host_port)
      {
        "localhost:3000" => ENV.fetch("HANDSHAKE_OUTBOUND_URL_3000", "http://localhost"),
        "localhost:3001" => ENV.fetch("HANDSHAKE_OUTBOUND_URL_3001", "http://app_b"),
        "127.0.0.1:3000" => ENV.fetch("HANDSHAKE_OUTBOUND_URL_3000", "http://localhost"),
        "127.0.0.1:3001" => ENV.fetch("HANDSHAKE_OUTBOUND_URL_3001", "http://app_b")
      }[host_port]
    end

    private_class_method :mapping_for
  end
end
