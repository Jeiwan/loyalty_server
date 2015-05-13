class CreateLoyaltyGiftCategories < ActiveRecord::Migration
  def change
    create_table :loyalty_gift_categories do |t|
      t.integer :gift_id
      t.integer :number
      t.decimal :threshold, precision: 10, scale: 2

      t.timestamps
    end
    add_index :loyalty_gift_categories, :gift_id
  end
end
