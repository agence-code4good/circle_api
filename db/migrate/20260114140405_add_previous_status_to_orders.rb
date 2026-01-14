class AddPreviousStatusToOrders < ActiveRecord::Migration[8.1]
  def change
    add_column :orders, :previous_status, :integer
  end
end
