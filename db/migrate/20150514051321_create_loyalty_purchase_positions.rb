class CreateLoyaltyPurchasePositions < ActiveRecord::Migration
  def change
    create_table :loyalty_purchase_positions do |t|
      t.string :uuid, limit: 36
      t.string :purchase_uuid, limit: 36
      t.string :product_uuid, limit: 36
      t.integer :quantity
      t.decimal :price, precision: 10, scale: 2
      t.decimal :sum, precision: 10, scale: 2

      t.timestamps
    end
    add_index :loyalty_purchase_positions, :uuid, unique: true
    add_index :loyalty_purchase_positions, :purchase_uuid
    add_index :loyalty_purchase_positions, :product_uuid
  end
end
