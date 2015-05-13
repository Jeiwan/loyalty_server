# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_card, class: 'Loyalty::Card' do
    number '123456'
    status 0
    balance 0.0
  end
end
