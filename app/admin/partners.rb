# frozen_string_literal: true

ActiveAdmin.register Partner do
  permit_params :name, :code, :remote_base_url, :linkage_code_remote,
                :auth_token_for_set, :pinned_public_key_for_set, :handshake_status

  filter :id
  filter :name
  filter :code
  filter :remote_base_url
  filter :handshake_status
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :name
    column :code
    column "Token" do |partner|
      partner.auth_token_digest.present? ? "Défini" : "Non défini"
    end
    column :remote_base_url
    column :handshake_status
    column :pinned_public_key_fingerprint do |p|
      p.pinned_public_key_fingerprint&.truncate(16)
    end
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :name
      row :code
      row "Token" do |partner|
        partner.auth_token_digest.present? ? "Défini à la création (non affiché)" : "Non défini"
      end
      row :remote_base_url
      row :linkage_code_remote
      row :handshake_status
      row :handshake_version
      row :pinned_public_key_fingerprint
      row :inbound_challenge_verified_at
      row :last_challenge_at
      row :last_successful_exchange_at
      row :created_at
      row :updated_at
    end

    panel "Aliases pour ce partenaire (en tant qu'émetteur)" do
      table_for resource.partner_aliases do
        column :external_id
        column "Partenaire cible" do |alias_record|
          target = Partner.find_by(code: alias_record.partner_code)
          if target
            link_to "#{target.name} (#{target.code})", admin_partner_path(target)
          else
            alias_record.partner_code
          end
        end
        column :created_at
        column "Voir l'alias" do |alias_record|
          link_to "Voir", admin_partner_alias_path(alias_record)
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Partenaire" do
      f.input :name
      f.input :code
      if f.object.new_record? || f.object.auth_token_digest.blank?
        f.input :auth_token_for_set,
                as: :password,
                label: "Token (saisi une seule fois, non ré-affiché)",
                input_html: { autocomplete: "new-password" }
      else
        para "Un token est déjà défini pour ce partenaire. Il n'est pas affiché et ne peut pas être modifié depuis l'interface."
      end
    end
    f.inputs "Handshake" do
      f.input :remote_base_url,
              hint: "URL de base de la CircleAPI distante (HTTPS en prod)."
      f.input :linkage_code_remote, hint: "Notre code chez ce partenaire (X-Partner-Code sortant depuis CircUI)"
      f.input :pinned_public_key_for_set, as: :text, label: "Clé publique (base64, optionnel)",
              hint: "Ou utiliser « Récupérer clé publique » après création."
      f.input :handshake_status, as: :select, collection: Partner::HANDSHAKE_STATUSES, include_blank: false
    end
    f.actions
  end

  action_item :fetch_identity, only: :show do
    link_to "Récupérer clé publique", fetch_identity_admin_partner_path(resource), method: :post, class: "action-item-button"
  end

  action_item :approve_key, only: :show, if: proc { resource.handshake_status == "key_mismatch" } do
    link_to "Ré-approuver la clé", approve_key_admin_partner_path(resource), method: :post,
            class: "action-item-button",
            data: { confirm: "Épingler la clé actuelle du partenaire (TOFU) et repasser en pending ?" }
  end

  member_action :fetch_identity, method: :post do
    result = Handshake::FetchIdentity.new(resource).call
    redirect_to admin_partner_path(resource),
                notice: "Clé publique épinglée (v#{result[:key_version]})"
  rescue Handshake::FetchIdentity::FetchError => e
    redirect_to admin_partner_path(resource), alert: e.message
  end

  member_action :approve_key, method: :post do
    result = Handshake::FetchIdentity.new(resource, approve_rotation: true).call
    resource.update!(handshake_status: "pending") unless resource.handshake_status == "pending"
    redirect_to admin_partner_path(resource),
                notice: "Clé ré-approuvée. Relancer les challenges. (#{result[:key_version]})"
  rescue Handshake::FetchIdentity::FetchError => e
    redirect_to admin_partner_path(resource), alert: e.message
  end
end
