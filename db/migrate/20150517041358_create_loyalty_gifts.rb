class CreateLoyaltyGifts < ActiveRecord::Migration
  def change
    create_table :loyalty_gifts do |t|
      t.timestamps
    end
  end
end
