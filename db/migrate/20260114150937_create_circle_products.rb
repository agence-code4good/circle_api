class CreateCircleProducts < ActiveRecord::Migration[8.1]
  def change
    create_table :circle_products do |t|
      t.timestamps
    end
  end
end
