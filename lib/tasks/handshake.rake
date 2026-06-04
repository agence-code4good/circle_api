# frozen_string_literal: true

namespace :handshake do
  desc "Generate Ed25519 instance identity (or rotate if ROTATE=1)"
  task generate_identity: :environment do
    if ENV["ROTATE"] == "1"
      identity = Handshake::IdentityService.rotate!
      puts "Identité instance régénérée (key_version=#{identity.key_version})"
    else
      identity = Handshake::IdentityService.ensure!
      puts "Identité instance prête (key_version=#{identity.key_version})"
      puts "GET /api/identity pour la clé publique"
    end
  end

  desc "Create pending PartnerConnections for partners missing one (requires REMOTE_BASE_URL=url)"
  task migrate_partners: :environment do
    remote_url = ENV.fetch("REMOTE_BASE_URL", "http://localhost:3000")

    Partner.find_each do |partner|
      next if partner.partner_connections.exists?

      inbound = Handshake::TokenGenerator.generate
      connection = partner.partner_connections.create!(
        remote_base_url: remote_url,
        inbound_token: inbound,
        status: "pending"
      )
      puts "Partner #{partner.code}: connection ##{connection.id} créée"
      puts "  inbound token (one-time): #{inbound}"
    end
  end
end
