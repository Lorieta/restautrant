class AddRememberDigestToUsers < ActiveRecord::Migration[7.0]
  def change
    add_column :users, :remember_digest, :string
    add_index :users, :remember_digest
  end
end
