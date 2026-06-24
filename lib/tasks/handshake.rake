# frozen_string_literal: true

namespace :handshake do
  desc "Import Ed25519 instance identity from CircUI (PUBLIC_KEY, PRIVATE_KEY, KEY_VERSION optional)"
  task import_identity: :environment do
    identity = Handshake::IdentityService.import!(
      public_key: ENV.fetch("PUBLIC_KEY"),
      private_key: ENV.fetch("PRIVATE_KEY"),
      key_version: ENV.fetch("KEY_VERSION", "1").to_i
    )
    puts "Identité importée (key_version=#{identity.key_version})"
    puts "GET /api/identity pour la clé publique"
  rescue Handshake::IdentityService::ImportError => e
    abort e.message
  end

  desc "Generate test identity (development/test only — not for CircUI integration)"
  task generate_identity: :environment do
    identity = Handshake::IdentityService.generate_for_dev!
    puts "Identité instance prête (key_version=#{identity.key_version})"
    puts "GET /api/identity pour la clé publique"
  rescue Handshake::IdentityService::ImportError => e
    abort e.message
  end

  desc "Set remote_base_url on partners missing one (REMOTE_BASE_URL=url)"
  task migrate_partners: :environment do
    remote_url = ENV.fetch("REMOTE_BASE_URL", "http://localhost:3000")

    Partner.where(remote_base_url: [ nil, "" ]).find_each do |partner|
      partner.update!(remote_base_url: remote_url, handshake_status: "pending")
      puts "Partner #{partner.code}: URL=#{remote_url}"
      puts "  token: #{partner.auth_token_digest.present? ? 'défini' : 'non défini — à saisir dans admin Partners'}"
    end
  end
end
