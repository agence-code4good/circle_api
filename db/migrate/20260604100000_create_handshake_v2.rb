class CreateHandshakeV2 < ActiveRecord::Migration[8.1]
  def change
    create_table :instance_identities do |t|
      t.string :public_key, null: false
      t.text :private_key, null: false
      t.integer :key_version, null: false, default: 1
      t.datetime :rotated_at

      t.timestamps
    end

    create_table :partner_connections do |t|
      t.references :partner, null: false, foreign_key: true
      t.string :remote_base_url, null: false
      t.string :linkage_code_local
      t.string :linkage_code_remote
      t.text :inbound_token
      t.text :outbound_token
      t.string :pinned_public_key
      t.string :pinned_public_key_fingerprint
      t.string :status, null: false, default: "pending"
      t.integer :handshake_version, null: false, default: 2
      t.datetime :last_challenge_at
      t.datetime :inbound_challenge_verified_at
      t.datetime :outbound_challenge_verified_at
      t.datetime :last_successful_exchange_at

      t.timestamps
    end

    add_index :partner_connections, [ :partner_id, :remote_base_url ], unique: true
    add_index :partner_connections, :status

    add_column :api_logs, :handshake_event, :string
    add_column :api_logs, :partner_connection_id, :bigint
    add_index :api_logs, :partner_connection_id

    remove_column :partners, :auth_token_digest, :string
  end
end
