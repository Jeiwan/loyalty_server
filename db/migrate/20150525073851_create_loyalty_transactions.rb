class CreateLoyaltyTransactions < ActiveRecord::Migration
  def change
    create_table :loyalty_transactions do |t|
      t.string :uuid, limit: 36
      t.string :card_number
      t.string :purchase_uuid, limi: 36
      t.integer :kind
      t.decimal :sum, precision: 10, scale: 2

      t.timestamps
    end
    add_index :loyalty_transactions, :uuid
    add_index :loyalty_transactions, :card_number
    add_index :loyalty_transactions, :purchase_uuid
    add_index :loyalty_transactions, :kind
  end
end
