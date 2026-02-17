class CreatePartnerAliases < ActiveRecord::Migration[8.1]
  def change
    create_table :partner_aliases do |t|
      t.references :partner, null: false, foreign_key: true
      t.string :external_id, null: false
      t.string :partner_code, null: false

      t.timestamps
    end

    add_index :partner_aliases, [ :partner_id, :external_id ], unique: true
  end
end

