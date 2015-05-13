module Loyalty
  class GiftPosition < ActiveRecord::Base
    attr_accessor :product_id

    belongs_to :gift
    belongs_to :gift_category
    belongs_to :product, foreign_key: 'product_uuid', primary_key: 'uuid'

    before_create :set_product_uuid, if: ->(gift_position) { gift_position.product_id.present? }

    delegate :name, to: :product, prefix: true, allow_nil: true
    delegate :number, to: :gift_category, prefix: true, allow_nil: true

    private

    def set_product_uuid
      self.product_uuid = Product.find(product_id).uuid
    end
  end
end
