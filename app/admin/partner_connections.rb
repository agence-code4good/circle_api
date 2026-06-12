# frozen_string_literal: true

ActiveAdmin.register PartnerConnection do
  permit_params :partner_id, :remote_base_url, :linkage_code_local, :linkage_code_remote,
                :inbound_token_for_set, :outbound_token_for_set, :status

  actions :all

  filter :partner
  filter :remote_base_url
  filter :status
  filter :created_at

  index do
    selectable_column
    id_column
    column :partner
    column :remote_base_url
    column :status
    column :pinned_public_key_fingerprint do |c|
      c.pinned_public_key_fingerprint&.truncate(16)
    end
    column :inbound_challenge_verified_at
    column :outbound_challenge_verified_at
    actions
  end

  show do
    attributes_table do
      row :id
      row :partner
      row :remote_base_url
      row :linkage_code_local
      row :linkage_code_remote
      row :status
      row :handshake_version
      row :pinned_public_key_fingerprint
      row :inbound_challenge_verified_at
      row :outbound_challenge_verified_at
      row :last_challenge_at
      row :last_successful_exchange_at
      row :created_at
      row :updated_at
    end

    if resource.generated_inbound_token.present?
      div class: "flash flash_warning" do
        para "Token inbound (affiché une seule fois) : #{resource.generated_inbound_token}"
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs "Connexion partenaire" do
      f.input :partner, collection: Partner.order(:name)
      f.input :remote_base_url,
              hint: "URL de base du partenaire (HTTPS en prod). En Docker : http://app ou http://app_b ; localhost:3000 est réécrit automatiquement."
      f.input :linkage_code_local, hint: "Code de liaison côté local"
      f.input :linkage_code_remote, hint: "Notre code chez le partenaire (X-Partner-Code sortant)"
      if f.object.new_record? || f.object.inbound_token.blank?
        f.input :inbound_token_for_set, as: :password, label: "Token inbound (généré si vide)",
                input_html: { autocomplete: "new-password" }
      else
        para "Token inbound déjà défini."
      end
      f.input :outbound_token_for_set, as: :password, label: "Token outbound (fourni par le partenaire)",
              input_html: { autocomplete: "new-password" }
      f.input :status, as: :select, collection: PartnerConnection::STATUSES, include_blank: false
    end
    f.actions
  end

  action_item :fetch_identity, only: :show do
    link_to "Récupérer clé publique", fetch_identity_admin_partner_connection_path(resource), method: :post, class: "action-item-button"
  end

  action_item :run_outbound_challenge, only: :show do
    link_to "Challenge sortant", outbound_challenge_admin_partner_connection_path(resource), method: :post, class: "action-item-button"
  end

  action_item :approve_key, only: :show, if: proc { resource.status == "key_mismatch" } do
    link_to "Ré-approuver la clé", approve_key_admin_partner_connection_path(resource), method: :post,
            data: { confirm: "Épingler la clé actuelle du partenaire (TOFU) et repasser en pending ?" }
  end

  member_action :fetch_identity, method: :post do
    result = Handshake::FetchIdentity.new(resource).call
    redirect_to admin_partner_connection_path(resource),
                notice: "Clé publique épinglée (v#{result[:key_version]})"
  rescue Handshake::FetchIdentity::FetchError => e
    redirect_to admin_partner_connection_path(resource), alert: e.message
  end

  member_action :outbound_challenge, method: :post do
    Handshake::ChallengeClient.new(resource).call
    redirect_to admin_partner_connection_path(resource), notice: "Challenge sortant réussi"
  rescue Handshake::ChallengeClient::ClientError => e
    redirect_to admin_partner_connection_path(resource), alert: e.message
  end

  member_action :approve_key, method: :post do
    result = Handshake::FetchIdentity.new(resource, approve_rotation: true).call
    resource.update!(status: "pending") unless resource.status == "pending"
    redirect_to admin_partner_connection_path(resource),
                notice: "Clé ré-approuvée. Relancer les challenges mutuels. (#{result[:key_version]})"
  rescue Handshake::FetchIdentity::FetchError => e
    redirect_to admin_partner_connection_path(resource), alert: e.message
  end

  controller do
    def create
      build_resource
      if resource.save
        token_msg = resource.generated_inbound_token ? " Token inbound : #{resource.generated_inbound_token}" : ""
        redirect_to admin_partner_connection_path(resource), notice: "Connexion créée.#{token_msg}"
      else
        render :new
      end
    end
  end
end
