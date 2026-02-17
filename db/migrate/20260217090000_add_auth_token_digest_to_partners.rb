class AddAuthTokenDigestToPartners < ActiveRecord::Migration[8.1]
  def up
    add_column :partners, :auth_token_digest, :string

    say_with_time "Migrating partner auth tokens to digest" do
      # On migre uniquement si la colonne auth_token existe encore
      if column_exists?(:partners, :auth_token)
        Partner.reset_column_information

        require "bcrypt"

        Partner.where.not(auth_token: [ nil, "" ]).find_each do |partner|
          digest = BCrypt::Password.create(partner.auth_token)
          partner.update_columns(auth_token_digest: digest)
        end
      end
    end

    # On peut ensuite supprimer la colonne en clair
    remove_column :partners, :auth_token, :string if column_exists?(:partners, :auth_token)
  end

  def down
    add_column :partners, :auth_token, :string unless column_exists?(:partners, :auth_token)
    remove_column :partners, :auth_token_digest, :string if column_exists?(:partners, :auth_token_digest)
  end
end
