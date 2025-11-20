class CreatePartners < ActiveRecord::Migration[8.1]
  def change
    create_table :partners do |t|
      t.string :name
      t.string :code

      t.timestamps
    end
  end
end
