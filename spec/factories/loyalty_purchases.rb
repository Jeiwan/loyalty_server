# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_purchase, class: 'Loyalty::Purchase' do
    card_number '1234'
    sum 10.0
    paid_by_bonus 0.0
    cashbox 'testCashbox'
    #pharmacy_uuid '1234'
    #receipt_uuid '1234'
    is_return false
    status 0

    receipt
    pharmacy

    trait :registered do
      status 1
    end
  end
end
