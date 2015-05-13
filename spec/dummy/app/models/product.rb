class Product < ActiveRecord::Base
  validates :name, presence: true
  validates :uuid, presence: true
end
