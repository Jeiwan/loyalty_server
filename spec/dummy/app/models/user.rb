class User < ActiveRecord::Base
  has_many :cashbox_operations
end
