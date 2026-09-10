class CreateHandshakeNonces < ActiveRecord::Migration[8.1]
  def change
    create_table :handshake_nonces do |t|
      t.references :partner_connection, null: false, foreign_key: true
      t.string :nonce, null: false
      t.string :purpose, null: false
      t.datetime :expires_at, null: false

      t.timestamps
    end

    add_index :handshake_nonces, [ :partner_connection_id, :nonce ], unique: true
    add_index :handshake_nonces, :expires_at
  end
end
