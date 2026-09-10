# frozen_string_literal: true

class ConsolidateHandshakeOnPartners < ActiveRecord::Migration[8.1]
  def up
    add_column :partners, :remote_base_url, :string
    add_column :partners, :auth_token_digest, :string
    add_column :partners, :pinned_public_key, :string
    add_column :partners, :pinned_public_key_fingerprint, :string
    add_column :partners, :handshake_status, :string, default: "pending", null: false
    add_column :partners, :handshake_version, :integer, default: 2, null: false
    add_column :partners, :inbound_challenge_verified_at, :datetime
    add_column :partners, :outbound_challenge_verified_at, :datetime
    add_column :partners, :last_challenge_at, :datetime
    add_column :partners, :last_successful_exchange_at, :datetime
    add_column :partners, :linkage_code_remote, :string
    add_index :partners, :handshake_status

    migrate_partner_connections_to_partners

    add_column :handshake_nonces, :partner_id, :bigint
    migrate_handshake_nonces_to_partners

    change_column_null :handshake_nonces, :partner_id, false
    remove_index :handshake_nonces, column: %i[partner_connection_id nonce]
    remove_foreign_key :handshake_nonces, :partner_connections
    remove_column :handshake_nonces, :partner_connection_id
    add_index :handshake_nonces, %i[partner_id nonce], unique: true
    add_foreign_key :handshake_nonces, :partners, on_delete: :cascade

    remove_index :api_logs, :partner_connection_id
    remove_column :api_logs, :partner_connection_id

    drop_table :partner_connections
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def migrate_partner_connections_to_partners
    return unless table_exists?(:partner_connections)

    require "bcrypt"

    say_with_time "Copying partner_connections onto partners" do
      legacy_partner_connection_class.find_each do |conn|
        partner = Partner.find_by(id: conn.partner_id)
        next unless partner

        attrs = {
          remote_base_url: conn.read_attribute(:remote_base_url),
          pinned_public_key: conn.read_attribute(:pinned_public_key),
          pinned_public_key_fingerprint: conn.read_attribute(:pinned_public_key_fingerprint),
          handshake_status: conn.read_attribute(:status),
          handshake_version: conn.read_attribute(:handshake_version),
          inbound_challenge_verified_at: conn.read_attribute(:inbound_challenge_verified_at),
          outbound_challenge_verified_at: conn.read_attribute(:outbound_challenge_verified_at),
          last_challenge_at: conn.read_attribute(:last_challenge_at),
          last_successful_exchange_at: conn.read_attribute(:last_successful_exchange_at),
          linkage_code_remote: conn.read_attribute(:linkage_code_remote)
        }

        inbound = conn.inbound_token
        attrs[:auth_token_digest] = BCrypt::Password.create(inbound) if inbound.present?

        partner.update_columns(attrs)
      end
    end
  end

  def legacy_partner_connection_class
    @legacy_partner_connection_class ||= Class.new(ApplicationRecord) do
      self.table_name = "partner_connections"
      encrypts :inbound_token
    end
  end

  def migrate_handshake_nonces_to_partners
    say_with_time "Repointing handshake_nonces to partners" do
      execute <<~SQL.squish
        UPDATE handshake_nonces
        SET partner_id = partner_connections.partner_id
        FROM partner_connections
        WHERE handshake_nonces.partner_connection_id = partner_connections.id
      SQL
    end
  end
end
