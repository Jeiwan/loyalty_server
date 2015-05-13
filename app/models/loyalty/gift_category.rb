module Loyalty
  class GiftCategory < ActiveRecord::Base
    default_scope -> { order(number: :asc) }

    belongs_to :gift
    has_many :gift_positions, dependent: :destroy
    accepts_nested_attributes_for :gift_positions, allow_destroy: true

    validates :number, presence: true, uniqueness: true
    validates :threshold, presence: true, uniqueness: true
  end
end
