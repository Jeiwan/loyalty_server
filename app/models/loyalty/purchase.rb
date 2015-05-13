module Loyalty
  class Purchase < ActiveRecord::Base
    attr_accessor :gift_demanded, :certificate_issued

    belongs_to :card, primary_key: 'number', foreign_key: 'card_number'
    belongs_to :certificate, primary_key: 'number', foreign_key: 'certificate_number'
    belongs_to :pharmacy, primary_key: 'uuid', foreign_key: 'pharmacy_uuid'
    belongs_to :receipt, primary_key: 'uuid', foreign_key: 'receipt_uuid'
    belongs_to :user
    has_many :purchase_positions, dependent: :destroy, primary_key: 'uuid', foreign_key: 'purchase_uuid'
    accepts_nested_attributes_for :purchase_positions
    has_many :transactions, dependent: :destroy, primary_key: 'uuid', foreign_key: 'purchase_uuid'

    validates :cashbox, presence: true
    validates :paid_by_bonus, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
    validates :pharmacy_uuid, presence: true
    validates :receipt_uuid, presence: true
    validates :sum, presence: true, numericality: { greater_than: 0 }

    before_create :check_reference_purchase, if: :is_return
    before_create :set_uuid
    after_create :apply_gift, if: ->(purchase) { purchase.paid_by_bonus > 0 }

    delegate :name, :code, to: :pharmacy, allow_nil: true, prefix: true
    delegate :name, to: :user, allow_nil: true, prefix: true
    delegate :code, to: :pharmacy, allow_nil: true, prefix: true
    delegate :balance, to: :card, allow_nil: true, prefix: true

    enum status: [:initiated, :registered, :cancelled]
    paginates_per 40

    scope :sells, -> { where(is_return: false) }

    class << self
      def validate_gift(purchase_params)
        gifts = Loyalty::GiftPosition.pluck(:product_uuid)
        available_gifts = purchase_params[:purchase_positions_attributes].select do |position|
          gifts.include?(position[:product_uuid])
        end
        return 0 unless available_gifts.present?

        fail 'В чеке может быть только один подарок' if available_gifts.count > 1
        fail 'Подарок должен быть в количестве 1 штуки' if available_gifts.first[:quantity].to_i > 1
        price = available_gifts.first[:price].to_f
        purchase_params[:purchase_positions_attributes].count > 1 ? price : price - 0.01
      end

      # Registers a purchase according to the specified parameters
      # 3 types of purchases:
      # 1. Purchase with card (with or without charge)
      # 2. Purchase with card and certificate (certificate as a gift)
      # 3. Purchase with certificate only
      def register(card_number, certificate_number, pin_code, certificate_in_receipt, purchase_params)
        if !card_number && !certificate_number
          fail 'Не указан номер карты или сертификата'
        end

        if certificate_in_receipt && certificate_number.blank?
          fail 'Не указан номер сертификата'
        elsif certificate_in_receipt && pin_code.blank?
          fail 'Не указан пин-код'
        end

        if card_number
          card = Loyalty::Card.find_by(number: card_number)
          fail 'Карта не найдена' if card.blank?
          fail 'Карта не активирована' if card.inactive?
          fail 'Карта заблокирована' if card.blocked?
        end

        if certificate_number
          certificate = Certificate.find_by(number: certificate_number)
          fail 'Сертификат не найден' if certificate.blank?
          fail 'Сертификат не активирован' if certificate.inactive?
          fail 'Сертификат уже был использован' if certificate.used?
          fail 'В чеке отсутствует сертификат' if card_number.present? && !certificate_in_receipt
          certificate.check_pin_code!(pin_code) if certificate_in_receipt
        end

        if certificate_number && !certificate_in_receipt && !card_number
          purchase = certificate.build_purchase(purchase_params)
        else
          purchase = card.purchases.new(purchase_params)
        end


        transaction do
          purchase.save!
          purchase.commit!

          if card_number && certificate_number && certificate_in_receipt
            certificate.activate!(card_number)
            purchase.certificate_issued = true
          elsif certificate_number && !card_number && !certificate_in_receipt
            certificate.used!
          end
        end

        purchase.reload
      end
    end

    def can_charge?
      sum > Settings.loyalty.family_money_box.charge_threshold
    end

    def commit!
      raise 'Продажа уже подтверждена' if registered?
      raise 'Нельзя подтвердить отмененную продажу' if cancelled?

      Purchase.transaction do
        if card.present?
          charge_bonuses
          discharge_bonuses

          if paid_by_bonus.present? && paid_by_bonus > 0
            card.deactivated!
          end

          if is_return && reference_purchase.find_gift.present?
            card.active!
          end
        end

        registered!
      end
    end

    def reference_purchase
      @reference_purchase = card.purchases.where(
        is_return: false,
        card_number: card_number,
        receipt_uuid: receipt_uuid,
        cashbox: cashbox,
        pharmacy_uuid: pharmacy_uuid,
        status: 1
      ).last
    end

    def has_charge?
      charge.present?
    end

    def has_discharge?
      discharge.present?
    end

    def charge
      @charge ||= transactions.where(kind: 0).where('sum > 0').first
    end

    def discharge
      @discharge ||= transactions.where(kind: 1).where('sum > 0').first
    end

    def charge_sum
      return 0 unless has_charge?
      charge.sum.to_f
    end

    def discharge_sum
      return 0 unless has_discharge?
      discharge.sum.to_f
    end

    def find_gift
      return unless paid_by_bonus.present? && paid_by_bonus > 0
      possible_gifts = purchase_positions.where('price = ? OR price = ?', paid_by_bonus, paid_by_bonus + 0.01).pluck(:product_uuid)
      GiftPosition.where(product_uuid: possible_gifts).first
    end

    def has_certificate?
      find_gift.product_uuid == Settings.loyalty.family_money_box.certificate_uuid
    end

    def cancel
      Loyalty::Purchase.transaction do
        transactions.destroy_all
        card.recalculate_balance! if card.present?
        cancelled!
      end
    end

    private

    def set_uuid
      self.uuid = SecureRandom.uuid
    end

    def charge_bonuses
      if is_return && reference_purchase.has_charge?
        transactions.create(card: card, kind: 1, sum: sum)
      elsif !is_return
        return unless can_charge?
        transactions.create(card: card, kind: 0, sum: sum)
        card.active! if card.inactive?
      end
    end

    def discharge_bonuses
      if is_return && reference_purchase.paid_by_bonus > 0
        transactions.create(card: card, kind: 0, sum: reference_purchase.paid_by_bonus)
      elsif paid_by_bonus > 0
        transactions.create(card: card, kind: 1, sum: paid_by_bonus)
      end
    end

    def check_reference_purchase
      raise 'Не найдена возвращаемая продажа' unless reference_purchase
    end

    def available_gifts
      @available_gifts = begin
        all_gifts = card.available_gifts.flat_map { |c| c[:gifts].map { |g| g[:product_uuid] } }
        purchase_positions.where(product_uuid: all_gifts)
      end
    end

    def apply_gift
      if certificate.present?
        update(paid_by_bonus: certificate.calculate_discount)
      elsif card.present?
        fail 'Нет доступных подарков для данной карты' unless available_gifts.present?
        fail 'В чеке может быть только один подарок' if available_gifts.count > 1
        fail 'Подарок должен быть в количестве 1 штуки' if available_gifts.first.quantity > 1
        gift_price = available_gifts.first[:price].to_f
        price = purchase_positions.count > 1 ? gift_price : (gift_price - 0.01).round(2)
        fail 'Списанные баллы не совпадают с ценой подарка' unless price.to_f == paid_by_bonus.to_f
        update(paid_by_bonus: price)
      end
    end
  end
end
