# frozen_string_literal: true

ActiveAdmin.register InstanceIdentity do
  actions :index, :show

  config.sort_order = "key_version_desc"

  filter :key_version
  filter :public_key
  filter :rotated_at
  filter :created_at

  index do
    para "L'identité Ed25519 est fournie par CircUI (ou le SI intégrateur) à l'installation via handshake:import_identity.",
         style: "margin-bottom: 1em; color: #666;"
    column :id
    column :key_version
    column :public_key do |i|
      i.public_key.truncate(40)
    end
    column :rotated_at
    column :created_at
    actions
  end
end
