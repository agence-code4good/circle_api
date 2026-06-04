# frozen_string_literal: true

ActiveAdmin.register InstanceIdentity do
  actions :index, :show

  config.sort_order = "key_version_desc"

  filter :key_version
  filter :public_key
  filter :rotated_at
  filter :created_at

  index do
    column :id
    column :key_version
    column :public_key do |i|
      i.public_key.truncate(40)
    end
    column :rotated_at
    column :created_at
    actions
  end

  action_item :rotate_identity, only: :index do
    link_to "Régénérer identité instance", rotate_identity_admin_instance_identities_path,
            method: :post,
            data: { confirm: "Les partenaires devront ré-approuver la clé. Continuer ?" }
  end

  collection_action :rotate_identity, method: :post do
    identity = Handshake::IdentityService.rotate!
    redirect_to admin_instance_identities_path,
                alert: "Identité régénérée (v#{identity.key_version}). Les partenaires détecteront le changement au prochain échange."
  end
end
