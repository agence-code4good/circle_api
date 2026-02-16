class AddPartnerIdToUsers < ActiveRecord::Migration[8.1]
  def change
    add_reference :users, :partner, foreign_key: true, null: true
  end
end
