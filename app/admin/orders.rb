ActiveAdmin.register Order do
  permit_params :order_reference, :initial_order_reference,
  :buyer_id, :seller_id, :broker_id, :note, :status,
  :accompanying_document_url,
  :latest_instruction_due_date,
  :estimated_availability_earliest_at,
  order_lines_attributes: [ :id, :_destroy, :circle_code_json ]

  actions :all, except: []

  filter :id
  filter :buyer_id
  filter :broker_id
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
    column :broker_id
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
      row :broker_id
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

    f.inputs "Commande" do
      f.input :buyer_id,  as: :select, collection: Partner.all.map { |p| [ "#{p.name} (#{p.code})", p.code ] }
      f.input :broker_id, as: :select, collection: Partner.all.map { |p| [ "#{p.name} (#{p.code})", p.code ] }, include_blank: true
      f.input :seller_id, as: :select, collection: Partner.all.map { |p| [ "#{p.name} (#{p.code})", p.code ] }
      f.input :order_reference
      f.input :note
      f.input :status, as: :select, collection: Order.statuses.keys
      f.input :accompanying_document_url
      f.input :latest_instruction_due_date, as: :date_select
      f.input :estimated_availability_earliest_at, as: :date_select
    end

    f.inputs "Lignes de commande" do
      f.has_many :order_lines, allow_destroy: true, new_record: "Ajouter une ligne" do |line|
        line.input :circle_code_json,
                   as: :text,
                   label: "Circle code (JSON)",
                   hint: 'Coller le JSON, ex: { "C0": "11", "CLE": "055", "C1": "A0", "C2": "6", "C3": "A1", "C4": "A0", "C5": "00", "C10": "5238A0", "C11": "2017", "C13": "A7", "C31": "6" }',
                   input_html: { rows: 6 }
      end
    end

    f.actions
  end
end
