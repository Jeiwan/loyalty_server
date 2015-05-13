class AddUserIdToCashboxOperations < ActiveRecord::Migration
  def change
    add_column :cashbox_operations, :user_id, :integer
    add_index :cashbox_operations, :user_id
  end
end
