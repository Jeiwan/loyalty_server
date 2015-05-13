class CreatePharmacies < ActiveRecord::Migration
  def change
    create_table :pharmacies do |t|
      t.string :uuid
      t.string :name
      t.integer :code

      t.timestamps null: false
    end
    add_index :pharmacies, :uuid
  end
end
