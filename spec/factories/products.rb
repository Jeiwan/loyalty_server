FactoryGirl.define do
  factory :product do
    name 'product'
    uuid { SecureRandom.uuid }
  end
end
