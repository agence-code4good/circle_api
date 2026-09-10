# frozen_string_literal: true

class RemoveLinkageCodeLocalFromPartnerConnections < ActiveRecord::Migration[8.1]
  def change
    remove_column :partner_connections, :linkage_code_local, :string
  end
end
