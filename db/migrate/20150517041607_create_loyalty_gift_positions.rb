class CreateLoyaltyGiftPositions < ActiveRecord::Migration
  def change
    create_table :loyalty_gift_positions do |t|
      t.integer :gift_id
      t.integer :gift_category_id
      t.string :product_uuid, limit: 36

      t.timestamps
    end
    add_index :loyalty_gift_positions, :gift_id
    add_index :loyalty_gift_positions, :gift_category_id
    add_index :loyalty_gift_positions, :product_uuid
  end
end
