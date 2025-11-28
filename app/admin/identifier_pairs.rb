ActiveAdmin.register IdentifierPair do
  # Specify parameters which should be permitted for assignment
  permit_params :partner_id, :my_alias, :partner_alias, :active

  # For security, limit the actions that should be available
  actions :all, except: []

  # Add or remove filters to toggle their visibility
  filter :id
  filter :partner
  filter :my_alias
  filter :partner_alias
  filter :active
  filter :created_at
  filter :updated_at

  # Add or remove columns to toggle their visibility in the index action
  index do
    selectable_column
    id_column
    column :partner
    column :my_alias
    column :partner_alias
    column :active
    column :created_at
    column :updated_at
    actions
  end

  # Add or remove rows to toggle their visibility in the show action
  show do
    attributes_table_for(resource) do
      row :id
      row :partner
      row :my_alias
      row :partner_alias
      row :active
      row :created_at
      row :updated_at
    end
  end

  # Add or remove fields to toggle their visibility in the form
  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :partner
      f.input :my_alias
      f.input :partner_alias
      f.input :active
    end
    f.actions
  end
end
