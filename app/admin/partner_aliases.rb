ActiveAdmin.register PartnerAlias do
  permit_params :partner_id, :external_id, :partner_code

  actions :all, except: []

  filter :partner
  filter :external_id
  filter :partner_code
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :partner
    column :external_id
    column :partner_code
    column :created_at
    column :updated_at
    actions
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :partner
      f.input :external_id
      f.input :partner_code, as: :select, collection: Partner.all.pluck(:code), include_blank: false
    end
    f.actions
  end
end

