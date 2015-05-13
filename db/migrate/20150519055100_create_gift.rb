class CreateGift < ActiveRecord::Migration
  def up
    Loyalty::Gift.create
  end

  def down
    Loyalty::Gift.first.destroy
  end
end
