# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_transaction, class: 'Loyalty::Transaction' do
    uuid '1234567890'
    kind 1
    sum 10.0

    association :card, factory: :loyalty_gift
    association :purchase, factory: :loyalty_purchase
  end
end
