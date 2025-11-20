class AddAuthTokenToPartners < ActiveRecord::Migration[8.1]
  def change
    add_column :partners, :auth_token, :string
  end
end
