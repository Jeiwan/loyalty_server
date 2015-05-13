class CreateProducts < ActiveRecord::Migration
  def change
    create_table :products do |t|
      t.string :name
      t.string :uuid, limit: 36
    end
    add_index :products, :uuid
  end
end
