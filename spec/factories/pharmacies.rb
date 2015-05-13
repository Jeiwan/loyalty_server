# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :pharmacy do
    uuid { SecureRandom.uuid }
    sequence(:name) { |n| "Pharmacy #{n}" }
    code 1
  end
end
