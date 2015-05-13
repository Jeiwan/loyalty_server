# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :receipt do
    uuid { SecureRandom.uuid }
    cashbox_operation
  end
end
