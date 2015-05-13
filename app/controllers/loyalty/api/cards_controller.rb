module Loyalty
  class Api::CardsController < Api::ApiController
    before_action :validate_pharmacy
    skip_authorization_here
    respond_to :json
    before_action :set_card
    before_action :check_deactivated_card, except: [:check_for_return]
    before_action :check_blocked_card

    def balance
      balance = @card.balance.to_f
      gifts = @card.available_gifts
      if @card.active?
        result = { balance: balance }
        result[:gifts] = gifts if gifts.present?
        result[:certificate_available] = @card.certificate_available? if @card.certificate_available?
      else
        result = { inactive: true }
      end
      result[:number] = @card.number

      render json: { status: 0, response: result }, status: 200
    end

    def activate
      if @card.active?
        fail 'Карта уже активирована'
      elsif @card.inactive?
        @card.active!
      else
        fail 'Ошибка активации карты'
      end
      render json: { status: 0, response: 'Карта успешно зарегистрирована' }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    def check_for_return
      purchase = Purchase.find_by(receipt_uuid: params[:receipt_uuid], is_return: false, status: 1)
      fail 'Продажа не найдена' unless purchase.present?
      fail 'Карта деактивирована' if @card.deactivated? && purchase.paid_by_bonus == 0.0
      fail 'Продажа была совершена по другой карте' if purchase.card != @card
      render json: { status: 0, response: true }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    private

    def set_card
      @card = Card.where(number: params[:number]).first
      return render json: { status: 1, response: 'Карта с таким номером не найдена' }, status: 200 unless @card
    end
  end
end
