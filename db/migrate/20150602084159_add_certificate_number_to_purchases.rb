class AddCertificateNumberToPurchases < ActiveRecord::Migration
  def change
    add_column :loyalty_purchases, :certificate_number, :string
    add_index :loyalty_purchases, :certificate_number
  end
end
