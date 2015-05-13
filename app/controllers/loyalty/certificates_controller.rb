module Loyalty
  class CertificatesController < ApplicationController
    skip_authorization_here

    def index
      if request.xhr?
        order_column = params[:sortName] || 'created_at'
        order_direction = params[:sortOrder].try(:to_sym) || :desc

        @certificates = Certificate.order(order_column => order_direction)

        if params[:filter].present?
          filter = JSON.parse(params[:filter], symbolize_names: true)
          query = []

          if filter[:status].present?
            status = I18n.t('activerecord.attributes.loyalty/certificate.status').find { |_, v| v == filter[:status] }[0]
            query << "status = '#{Certificate.statuses[status.to_sym]}'"
          end

          if filter[:number].present?
            query << "number like '%#{filter[:number]}%'"
          end

          if filter[:card_number].present?
            query << "card_number like '%#{filter[:number]}%'"
          end

          @certificates =  @certificates.where(query.join(' AND '))
        end

        total = @certificates.count

        @certificates = @certificates.page(params[:pageNumber]).per(params[:pageSize]).map do |certificate|
          {
            number: certificate.number,
            status: I18n.t("activerecord.attributes.loyalty/certificate.status.#{certificate.status}"),
            purchase_sum: certificate.purchase_sum,
            card_number: certificate.card_number

          }
        end

        render json: { total: total, rows: @certificates }
      else
        @certificates = []
      end
    end
  end
end
