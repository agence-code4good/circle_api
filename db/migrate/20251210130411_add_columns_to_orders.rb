class AddColumnsToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :accompanying_document_url, :string
    add_column :orders, :latest_instruction_due_date, :date
    add_column :orders, :estimated_availability_earliest_at, :date
  end
end
