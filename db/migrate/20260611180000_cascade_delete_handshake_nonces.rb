class CascadeDeleteHandshakeNonces < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :handshake_nonces, :partner_connections
    add_foreign_key :handshake_nonces, :partner_connections, on_delete: :cascade
  end
end
