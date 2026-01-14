class CreateCircleCodes < ActiveRecord::Migration[8.1]
  def change
    create_table :circle_codes do |t|
      t.references :circle_product, null: false, foreign_key: true
      t.string :code, null: false
      t.jsonb :value, null: false, default: {}

      t.timestamps
    end

    add_index :circle_codes, [ :circle_product_id, :code ], unique: true

    add_index :circle_codes, :code
    add_index :circle_codes, :value, using: :gin
  end
end
