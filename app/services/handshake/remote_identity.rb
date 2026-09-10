# frozen_string_literal: true

require "net/http"
require "json"

module Handshake
  class RemoteIdentity
    class FetchError < StandardError; end

    def self.fetch(partner)
      new(partner).fetch
    end

    def initialize(partner)
      @partner = partner
    end

    def fetch
      response = http_get(identity_url)
      raise FetchError, "HTTP #{response.code}" unless response.is_a?(Net::HTTPSuccess)

      payload = JSON.parse(response.body)
      public_key = payload["public_key"]
      raise FetchError, "public_key manquante" if public_key.blank?

      {
        public_key: public_key,
        key_version: payload["key_version"],
        algorithm: payload["algorithm"]
      }
    rescue JSON::ParserError => e
      raise FetchError, "Réponse JSON invalide: #{e.message}"
    end

    private

    def identity_url
      "#{resolved_remote_base_url}/api/identity"
    end

    def resolved_remote_base_url
      OutboundUrl.resolve(@partner.remote_base_url)
    end

    def http_get(url)
      uri = URI.parse(url)
      Net::HTTP.start(uri.host, uri.port, use_ssl: uri.scheme == "https", open_timeout: 10, read_timeout: 10) do |http|
        http.get(uri.request_uri, { "Accept" => "application/json" })
      end
    rescue Errno::ECONNREFUSED, SocketError => e
      raise FetchError, connection_refused_message(e)
    end

    def connection_refused_message(error)
      target = resolved_remote_base_url
      stored = @partner.remote_base_url
      hint = stored != target ? " (URL utilisée : #{target}, enregistrée : #{stored})" : ""
      "Connexion refusée vers #{target}#{hint}. #{error.message}."
    end
  end
end
