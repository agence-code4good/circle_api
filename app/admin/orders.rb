ActiveAdmin.register Order do
  permit_params :buyer_id, :note, :order_reference, :seller_id, :status

  actions :all, except: []

  filter :id
  filter :buyer_id
  filter :created_at
  filter :note
  filter :order_reference
  filter :seller_id
  filter :status
  filter :updated_at

  index do
    selectable_column
    id_column
    column :order_reference
    column :buyer_id
    column :seller_id
    column :note
    column :status
    column :created_at
    column :updated_at
    actions
  end

  show do
    attributes_table_for(resource) do
      row :id
      row :buyer_id
      row :created_at
      row :note
      row :order_reference
      row :seller_id
      row :status
      row :updated_at
    end

    panel "Lignes de commande" do
      table_for resource.order_lines do
        column :id
        column "Code Circle", :circle_code do |order_line|
          pre JSON.pretty_generate(order_line.circle_code || {})
        end
        column "Volume total", :total_volume
        column :created_at
        column :updated_at
      end
    end
  end

  form do |f|
    f.semantic_errors(*f.object.errors.attribute_names)
    f.inputs do
      f.input :buyer_id
      f.input :note
      f.input :order_reference
      f.input :seller_id
      f.input :status
    end
    f.actions
  end
end
