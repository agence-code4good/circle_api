class CreateBrokerMandates < ActiveRecord::Migration[8.1]
  def change
    create_table :broker_mandates do |t|
      t.references :broker_partner, null: false, foreign_key: { to_table: :partners }
      t.references :buyer_partner, null: false, foreign_key: { to_table: :partners }
      t.boolean :active, null: false, default: true
      t.datetime :starts_at
      t.datetime :ends_at

      t.timestamps
    end

    add_index :broker_mandates, [ :broker_partner_id, :buyer_partner_id ],
              unique: true,
              name: "index_broker_mandates_on_broker_and_buyer"
    add_index :broker_mandates, :active
  end
end

