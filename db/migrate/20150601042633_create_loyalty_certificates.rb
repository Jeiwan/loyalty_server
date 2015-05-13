class CreateLoyaltyCertificates < ActiveRecord::Migration
  def change
    create_table :loyalty_certificates do |t|
      t.string :number
      t.integer :status, default: 0
      t.string :card_number
      t.integer :pin_code

      t.timestamps
    end
    add_index :loyalty_certificates, :number
    add_index :loyalty_certificates, :status
    add_index :loyalty_certificates, :card_number
  end
end
