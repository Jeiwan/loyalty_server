class CreateReceipts < ActiveRecord::Migration
  def change
    create_table :receipts do |t|
      t.integer :cashbox_operation_id
      t.string :uuid

      t.timestamps null: false
    end
    add_index :receipts, :cashbox_operation_id
    add_index :receipts, :uuid
  end
end
