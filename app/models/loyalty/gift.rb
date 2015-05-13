module Loyalty
  class Gift < ActiveRecord::Base
    has_many :gift_positions, dependent: :destroy
    has_many :gift_categories, dependent: :destroy
    accepts_nested_attributes_for :gift_categories, allow_destroy: true
  end
end
