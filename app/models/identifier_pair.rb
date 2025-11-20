class IdentifierPair < ApplicationRecord
  belongs_to :partner
  validates :my_alias, presence: true
  validates :partner_alias, presence: true
end
