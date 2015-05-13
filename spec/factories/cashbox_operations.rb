# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :cashbox_operation do
    sequence(:number) { |n| n }

    user
  end
end
