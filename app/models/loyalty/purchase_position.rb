module Loyalty
  class PurchasePosition < ActiveRecord::Base
    belongs_to :purchase, primary_key: 'uuid', foreign_key: 'purchase_uuid'
    belongs_to :product, primary_key: 'uuid', foreign_key: 'product_uuid'
    has_one :gift_position, primary_key: 'product_uuid', foreign_key: 'product_uuid'

    validates :product_uuid, presence: true
    validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
    validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
    validates :sum, presence: true, numericality: { greater_than_or_equal_to: 0 }

    before_create :set_uuid

    delegate :name, to: :product, prefix: true, allow_nil: true

    private

    def set_uuid
      self.uuid = SecureRandom.uuid
    end
  end
end
