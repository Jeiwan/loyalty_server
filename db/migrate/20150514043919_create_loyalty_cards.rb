class CreateLoyaltyCards < ActiveRecord::Migration
  def change
    create_table :loyalty_cards do |t|
      t.string :number
      t.integer :status, default: 0
      t.decimal :balance, precision: 10, scale: 2, default: 0

      t.timestamps
    end
  end
end
