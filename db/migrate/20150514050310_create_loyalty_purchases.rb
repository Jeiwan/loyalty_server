class CreateLoyaltyPurchases < ActiveRecord::Migration
  def change
    create_table :loyalty_purchases do |t|
      t.string :uuid, limit: 36
      t.string :card_number
      t.decimal :sum, precision: 10, scale: 2
      t.decimal :paid_by_bonus, precision: 10, scale: 2
      t.string :cashbox
      t.string :pharmacy_uuid, limit: 36
      t.string :receipt_uuid, limit: 36
      t.boolean :is_return, default: false
      t.integer :status, default: 0

      t.timestamps
    end
    add_index :loyalty_purchases, :card_number
    add_index :loyalty_purchases, :pharmacy_uuid
    add_index :loyalty_purchases, :receipt_uuid
    add_index :loyalty_purchases, :status
  end
end
