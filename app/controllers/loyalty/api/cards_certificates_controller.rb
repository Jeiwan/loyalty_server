module Loyalty
  class Api::CardsCertificatesController < Api::ApiController
    before_action :validate_pharmacy
    skip_authorization_here
    respond_to :json
    before_action :check_number

    def check
      @card = Card.where(number: params[:number]).first
      if @card.present?
        check_deactivated_card or return
        check_blocked_card or return
        card_balance or return
      else
        @certificate = Certificate.where(number: params[:number]).first
        if @certificate.present?
          check_inactive_certificate or return
          check_used_certificate or return
          check_certificate or return
        else
          return render json: { status: 1, response: 'Карта или сертификат не найдены' }, status: 200
        end
      end
    end

    private

    def card_balance
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

      render json: { status: 0, response: { card: result } }, status: 200
    end

    def check_certificate
      result = { number: @certificate.number }

      if params[:sum].present?
        result[:discount] = @certificate.calculate_discount(params[:sum].to_f)
      end

      render json: { status: 0, response: { certificate: result } }, status: 200
    end

    def check_number
      return render json: { status: 1, response: 'Не указан номер карты или сертификата' }, status: 200 unless params[:number].present?
    end
  end
end
