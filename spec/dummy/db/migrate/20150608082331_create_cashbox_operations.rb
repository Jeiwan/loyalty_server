class CreateCashboxOperations < ActiveRecord::Migration
  def change
    create_table :cashbox_operations do |t|
      t.integer :number

      t.timestamps null: false
    end
    add_index :cashbox_operations, :number
  end
end
