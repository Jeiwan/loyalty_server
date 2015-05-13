module Loyalty
  class Card < ActiveRecord::Base
    has_many :purchases, foreign_key: 'card_number', primary_key: 'number', dependent: :destroy
    has_many :transactions, foreign_key: 'card_number', primary_key: 'number', dependent: :destroy
    has_one :certificate, foreign_key: 'card_number', primary_key: 'number'

    validates :number, presence: true, uniqueness: true, numericality: true
    validates :status, presence: true
    validates :balance, presence: true, numericality: true

    enum status: [:inactive, :active, :deactivated, :blocked]
    paginates_per 40

    def available_gifts
      return [] if inactive? || deactivated?

      GiftCategory.where('threshold <= ?', balance).preload(:gift_positions).map do |category|
        gifts = category.gift_positions.map do |gift|
          { product_uuid: gift.product_uuid }
        end

        { category: category.number, gifts: gifts }
      end
    end

    def recalculate_balance!
      recalculate_balance
      save
    end

    def left_till_next_gift_category
      next_gift_category = GiftCategory.where('threshold > ?', balance).order(threshold: :asc).first
      return unless next_gift_category.present?
      threshold = next_gift_category.threshold
      (threshold - balance).to_f
    end

    def certificate_available?
      @certificate_available ||= available_gifts.any? do |category|
        category[:gifts].any? do |gift|
          gift[:product_uuid] == Settings.loyalty.family_money_box.certificate_uuid
        end
      end
    end

    private

    def recalculate_balance
      charge_sum = transactions.where(kind: 0).sum(:sum)
      writeoff_sum = transactions.where(kind: 1).sum(:sum)
      update(balance: charge_sum - writeoff_sum)
    end
  end
end
