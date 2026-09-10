# frozen_string_literal: true

class RemoveOutboundChallengeVerifiedAtFromPartners < ActiveRecord::Migration[8.1]
  def change
    remove_column :partners, :outbound_challenge_verified_at, :datetime
  end
end
