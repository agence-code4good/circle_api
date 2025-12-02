class AddInitialOrderReferenceToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :initial_order_reference, :string
  end
end
