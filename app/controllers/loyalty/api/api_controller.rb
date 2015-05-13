module Loyalty
  class Api::ApiController < ApplicationController
    around_action :log
    rescue_from StandardError do |exception|
      Loyalty::Logger.new.logger.error exception.message
    end

    helper_method :validate_pharmacy

    private

    def log_request
      data = request.body.string
      log = "#{request.method.upcase} #{request.original_fullpath} FROM #{request.remote_ip}"
      Loyalty::Logger.new.logger.info log
      Loyalty::Logger.new.logger.info "Request data: #{data}" if data.present?
    end

    def log_response
      Loyalty::Logger.new.logger.info "#{response.status} #{response.body}"
    end

    def log
      log_request
      yield
    ensure
      log_response
    end

    def check_deactivated_card
      return true unless @card.deactivated?
      render json: { status: 1, response: 'Карта деактивирована' }, status: 200
      return false
    end

    def check_blocked_card
      return true unless  @card.blocked?
      render json: { status: 1, response: 'Карта заблокирована' }, status: 200
      return false
    end

    def check_inactive_certificate
      return true unless @certificate.inactive?
      render json: { status: 1, response: 'Сертификат не активирован' }, status: 200
      return false
    end

    def check_used_certificate
      return true unless @certificate.used?
      render json: { status: 1, response: 'Сертификат уже был использован' }, status: 200
      return false
    end

    def validate_pharmacy
      unless PharmacySession.find
        return render json: { status: 1, response: 'Ошибка аутентификации аптеки' }, status: 200
      end
    end
  end
end
