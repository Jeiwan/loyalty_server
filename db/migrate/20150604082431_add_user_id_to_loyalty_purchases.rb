class AddUserIdToLoyaltyPurchases < ActiveRecord::Migration
  def change
    add_column :loyalty_purchases, :user_id, :integer
    add_index :loyalty_purchases, :user_id
  end
end
