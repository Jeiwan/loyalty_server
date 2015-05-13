class AddSingleAccessTokenToPharmacies < ActiveRecord::Migration
  def change
    add_column :pharmacies, :single_access_token, :string, limit: 18
  end
end
