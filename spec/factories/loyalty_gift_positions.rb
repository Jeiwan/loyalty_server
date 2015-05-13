# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_gift_position, class: 'Loyalty::GiftPosition' do
    association :gift, factory: :loyalty_gift
    association :gift_category, factory: :loyalty_gift_category
    product
  end
end
