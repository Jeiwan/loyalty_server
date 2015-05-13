module Loyalty
  class Api::PurchasesController < Api::ApiController
    before_action :validate_pharmacy
    skip_authorization_here
    respond_to :json

    def create
      card = Card.find_by(number: purchase_params[:card_number])
      fail 'Карта не найдена' if card.blank? && purchase_params[:certificate].blank?

      if card.present?
        fail 'Карта не зарегистрирована' if card.inactive?
        fail 'Карта заблокирована' if card.blocked?
        fail 'Не указан номер чека' unless purchase_params[:receipt_uuid].present?
      end

      @purchase = card.purchases.new(purchase_params)

      @purchase.save!
      @purchase.commit!

      if certificate && certificate_in_receipt?
        certificate.initiated!
      elsif certificate && no_certificate_in_receipt?
        certificate.used!
      end

      if purchase.card.present?
        result = {
          balance: purchase.card.balance.to_f,
          status: purchase.card.status,
          bonuses_added: purchase.charge_sum,
          bonuses_removed: purchase.discharge_sum
        }

        if purchase.certificate_issued
          result[:certificate_sum] = 2000
        end
      end

      if purchase.certificate.present? && no_certificate_in_receipt?
        result = {
          new_card_threshold: Settings.loyalty.family_money_box.charge_threshold,
          bonuses_removed: purchase.paid_by_bonus.to_f,
          certificate_number: purchase.certificate.number,
          status: purchase.certificate.status
        }
      end

      gift_taken = purchase.find_gift
      if gift_taken.present?
        result[:gift_taken] = gift_taken.gift_category.number
        result[:new_card_threshold] = Settings.loyalty.family_money_box.charge_threshold
      elsif purchase.card.present?
        available_gifts = purchase.card.available_gifts
        result[:gifts] = available_gifts if available_gifts.present?

        left_till_next_gift = purchase.card.left_till_next_gift_category
        result[:left_till_next_gift] = left_till_next_gift if left_till_next_gift.present?
      end

      render json: { status: 0, response: result }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    def commit
      render json: { status: 0, response: true }, status: 200
    end

    def rollback
      fail 'Не указан номер карты' unless params[:purchase][:card_number].present?
      fail 'Не указана касса' unless params[:purchase][:cashbox].present?
      fail 'Не указан номер чека' unless params[:purchase][:receipt_uuid].present?

      card = Card.find_by(number: purchase_params[:card_number])
      fail 'Карта не найдена' unless card
      fail 'Карта не зарегистрирована' if card.inactive?
      fail 'Карта заблокирована' if card.blocked?
      @purchase = card.purchases.registered.find_by!(purchase_params)
      @purchase.cancel

      render json: { status: 0, response: @purchase.cancelled? }, status: 200
    rescue ActiveRecord::RecordNotFound
      render json: { status: 1, response: 'Продажа не найдена' }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    def demand_gift
      card = Card.find_by(number: purchase_params[:card_number])
      fail 'Карта не найдена' unless card
      fail 'Карта не зарегистрирована' unless card.active?
      fail 'Не указан номер чека' unless purchase_params[:receipt_uuid].present?
      possible_gifts = card.available_gifts.flat_map { |c| c[:gifts].map { |g| g[:product_uuid] } }
      demanded_gifts = purchase_params[:purchase_positions_attributes].map { |p| p[:product_uuid] }
      fail 'Подарок не доступен для этой карты' unless possible_gifts.present? && (possible_gifts & demanded_gifts).present?

      bonus_to_spend = Purchase.validate_gift(purchase_params)

      render json: { status: 0, response: bonus_to_spend }, status: 200
    rescue ActiveRecord::RecordNotFound
      render json: { status: 1, response: 'Продажа не найдена' }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    def check_threshold
      fail 'Не указана сумма чека' unless params[:sum].present?
      result = params[:sum].to_f > Settings.loyalty.family_money_box.charge_threshold
      render json: { status: 0, response: result }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    private

    def purchase_params
      params.require(:purchase).permit(:card_number, :sum, :paid_by_bonus, :cashbox,
        :certificate, :pin_code, :user_id,
        :pharmacy_uuid, :receipt_uuid, :is_return, :gift_demanded, purchase_positions_attributes: [
          :product_uuid, :quantity, :price, :sum
      ])
    end

    def no_certificate_in_receipt?
      @no_certificate_in_receipt ||= !purchase_params[:purchase_positions_attributes].map { |p| p[:product_uuid] }.include?(Settings.loyalty.family_money_box.certificate_uuid)
    end

    def certificate_in_receipt?
      !no_certificate_in_receipt?
    end
  end
end
