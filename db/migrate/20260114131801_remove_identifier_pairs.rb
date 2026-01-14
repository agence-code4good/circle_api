class RemoveIdentifierPairs < ActiveRecord::Migration[8.1]
  def change
    drop_table :identifier_pairs
  end
end
