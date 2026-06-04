ActiveAdmin.register Partner do
  permit_params :name, :code

  actions :all, except: []

  filter :id
  filter :name
  filter :code
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :name
    column :code
    column "Connexions" do |partner|
      partner.partner_connections.count
    end
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :name
      row :code
      row :created_at
      row :updated_at
    end

    panel "Connexions handshake" do
      table_for resource.partner_connections do
        column :id
        column :remote_base_url
        column :status
        column "Actions" do |conn|
          link_to "Voir", admin_partner_connection_path(conn)
        end
      end
      para link_to "Nouvelle connexion", new_admin_partner_connection_path(partner_connection: { partner_id: resource.id })
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
        column :updated_at
        column "Voir l'alias" do |alias_record|
          link_to "Voir", admin_partner_alias_path(alias_record)
        end
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :name
      f.input :code
      para "Les tokens d'authentification sont gérés par les connexions handshake (PartnerConnection)."
    end
    f.actions
  end
end
