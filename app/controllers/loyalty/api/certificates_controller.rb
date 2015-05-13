module Loyalty
  class Api::CertificatesController < Api::ApiController
    before_action :validate_pharmacy
    skip_authorization_here
    respond_to :json
    before_action :set_certificate
    before_action :check_active_certificate, except: [:apply]
    before_action :check_inactive_certificate, except: [:check_pin_code, :check]
    before_action :check_used_certificate

    def check
      result = { number: @certificate.number }

      if params[:sum].present?
        result[:discount] = @certificate.calculate_discount(params[:sum].to_f)
      end

      render json: { status: 0, response: { certificate: result } }, status: 200
    end

    def check_pin_code
      fail 'Не указан пин-код' unless params[:pin_code].present?
      @certificate.check_pin_code!(params[:pin_code])
      render json: { status: 0, response: true }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    def apply
      render json: { status: 0, response: Settings.loyalty.family_money_box.certificate_sum }, status: 200
    rescue => e
      render json: { status: 1, response: e.message }, status: 200
    end

    private

    def set_certificate
      @certificate = Certificate.where(number: params[:number]).first
      return render json: { status: 1, response: 'Сертификат не найден' }, status: 200 unless @certificate.present?
    end

    def check_active_certificate
      return render json: { status: 1, response: 'Сертификат уже активирован' }, status: 200 if @certificate.active?
    end
  end
end
