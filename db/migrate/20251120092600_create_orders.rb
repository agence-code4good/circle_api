class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :buyer_id
      t.string :seller_id
      t.string :order_reference
      t.string :note
      t.integer :status

      t.timestamps
    end
  end
end
