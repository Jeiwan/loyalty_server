module Loyalty
  class Certificate < ActiveRecord::Base
    DISCOUNT = 2000

    belongs_to :card, primary_key: 'number', foreign_key: 'card_number'
    has_one :purchase, primary_key: 'number', foreign_key: 'certificate_number', dependent: :destroy

    validates :number, presence: true, uniqueness: true, numericality: true
    validates :pin_code, presence: true, numericality: true

    delegate :sum, to: :purchase, prefix: true, allow_nil: true

    enum status: [:inactive, :initiated, :active, :used]
    paginates_per 40

    def check_pin_code!(code)
      fail 'Не указан пин-код' unless code
      if pin_code == code.to_f
        initiated!
      else
        raise 'Неверный пин-код'
      end
    end

    def activate!(card_number)
      update(card_number: card_number, status: 2)
    end

    def calculate_discount(sum = nil)
      purchase_sum = sum || (purchase.sum + purchase.paid_by_bonus)
      purchase_sum > DISCOUNT ? DISCOUNT : purchase_sum - 0.01
    end
  end
end
