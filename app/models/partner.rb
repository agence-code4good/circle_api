class Partner < ApplicationRecord
  has_many :users, dependent: :nullify
  has_many :partner_aliases, dependent: :destroy
  before_validation :apply_auth_token_for_set, if: -> { auth_token_for_set.present? && auth_token_digest.blank? }

  attr_accessor :auth_token_for_set

  def self.main_partner
    find_by(code: "circle")
  end

  def self.ransackable_attributes(auth_object = nil)
    [ "code", "created_at", "id", "id_value", "name", "updated_at" ]
  end

  def set_auth_token(plain_token)
    return if plain_token.blank?

    self.auth_token_digest = BCrypt::Password.create(plain_token)
  end


  private

  def apply_auth_token_for_set
    set_auth_token(auth_token_for_set)
  end
end
