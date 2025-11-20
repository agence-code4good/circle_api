class CreateIdentifierPairs < ActiveRecord::Migration[8.1]
  def change
    create_table :identifier_pairs do |t|
      t.references :partner, null: false, foreign_key: true
      t.string :my_alias
      t.string :partner_alias
      t.boolean :active

      t.timestamps
    end
  end
end
