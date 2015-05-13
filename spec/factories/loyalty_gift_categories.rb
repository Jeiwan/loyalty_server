# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_gift_category, class: 'Loyalty::GiftCategory' do
    number 1
    threshold 10
    association :gift, factory: :loyalty_gift
  end
end
