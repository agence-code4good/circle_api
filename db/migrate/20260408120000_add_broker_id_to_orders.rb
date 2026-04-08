class AddBrokerIdToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :broker_id, :string
    add_index :orders, :broker_id
  end
end

