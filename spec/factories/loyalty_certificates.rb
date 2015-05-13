# Read about factories at https://github.com/thoughtbot/factory_girl

FactoryGirl.define do
  factory :loyalty_certificate, class: 'Loyalty::Certificate' do
    number '5678'
    status 0
    pin_code 5555
  end
end
