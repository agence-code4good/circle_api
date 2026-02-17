ActiveAdmin.register Partner do
  permit_params :name, :code, :auth_token_for_set

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
    column "Token" do |partner|
      partner.auth_token_digest.present? ? "Défini" : "Non défini"
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
      row "Token" do |partner|
        partner.auth_token_digest.present? ? "Défini à la création (non affiché)" : "Non défini"
      end
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
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
    f.actions
  end
end
