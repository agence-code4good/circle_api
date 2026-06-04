# frozen_string_literal: true

class InstanceIdentity < ApplicationRecord
  encrypts :private_key

  validates :public_key, :private_key, :key_version, presence: true
  validates :key_version, numericality: { only_integer: true, greater_than: 0 }

  def self.ransackable_attributes(_auth_object = nil)
    %w[created_at id key_version public_key rotated_at updated_at]
  end

  def self.ransackable_associations(auth_object = nil)
    []
  end
end
