module Loyalty
  class Transaction < ActiveRecord::Base
    belongs_to :card, primary_key: 'number', foreign_key: 'card_number'
    belongs_to :purchase, primary_key: 'uuid', foreign_key: 'purchase_uuid'

    validates :sum, presence: true, numericality: { greater_than_or_equal_to: 0 }

    enum kind: [:charge, :discharge]

    before_create :set_uuid
    after_create :update_card_balance

    private

    def set_uuid
      self.uuid = SecureRandom.uuid
    end

    def update_card_balance
      card.recalculate_balance!
    end
  end
end
