ActiveAdmin.register BrokerMandate do
  permit_params :broker_partner_id, :buyer_partner_id, :active, :starts_at, :ends_at

  actions :all, except: []

  filter :broker_partner
  filter :buyer_partner
  filter :active
  filter :starts_at
  filter :ends_at
  filter :created_at
  filter :updated_at

  index do
    selectable_column
    id_column
    column :broker_partner
    column :buyer_partner
    column :active
    column :starts_at
    column :ends_at
    column :created_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :broker_partner
      row :buyer_partner
      row :active
      row :starts_at
      row :ends_at
      row :created_at
      row :updated_at
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)

    f.inputs "Mandat courtier" do
      f.input :broker_partner, as: :select, collection: Partner.all.map { |p| [ "#{p.name} (#{p.code})", p.id ] }
      f.input :buyer_partner, as: :select, collection: Partner.all.map { |p| [ "#{p.name} (#{p.code})", p.id ] }
      f.input :active
      f.input :starts_at, as: :datetime_picker
      f.input :ends_at, as: :datetime_picker
    end

    f.actions
  end
end

