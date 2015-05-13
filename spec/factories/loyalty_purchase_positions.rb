# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_purchase_position, class: 'Loyalty::PurchasePosition' do
    purchase_uuid nil
    product_uuid '1234'
    quantity 1
    price 10.0
    sum 10.0
  end
end
