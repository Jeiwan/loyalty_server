class CashboxOperation < ActiveRecord::Base
  has_one :receipt
  belongs_to :user
end
