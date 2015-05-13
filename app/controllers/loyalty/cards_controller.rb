module Loyalty
  class CardsController < ApplicationController
    skip_authorization_here
    before_action :set_card, only: [:destroy, :block, :unblock]

    def index
      if request.xhr?
        order_column = params[:sortName] || 'created_at'
        order_direction = params[:sortOrder].try(:to_sym) || :desc

        @cards = Card.order(order_column => order_direction)

        if params[:filter].present?
          filter = JSON.parse(params[:filter], symbolize_names: true)
          query = []

          if filter[:status].present?
            status = I18n.t('activerecord.attributes.loyalty/card.status').find { |_, v| v == filter[:status] }[0]
            query << "status = '#{Card.statuses[status.to_sym]}'"
          end

          if filter[:number].present?
            query << "number like '%#{filter[:number]}%'"
          end

          if filter[:balance].present?
            query << "balance >= #{filter[:balance][:gte]}" if filter[:balance][:gte].present?
            query << "balance <= #{filter[:balance][:lte]}" if filter[:balance][:lte].present?
            query << "balance = #{filter[:balance][:eq]}" if filter[:balance][:eq].present?
          end

          @cards =  @cards.where(query.join(' AND '))
        end

        total = @cards.count

        @cards = @cards.page(params[:pageNumber]).per(params[:pageSize]).map do |card|
          {
            number: card.number,
            balance: card.balance,
            status: I18n.t("activerecord.attributes.loyalty/card.status.#{card.status}")
          }
        end

        render json: { total: total, rows: @cards }
      else
        @cards = []
      end
    end

    def upload
      return redirect_to cards_path unless params[:file].present?
      errors = Loyalty::CardUploadService.new(params[:file]).process_file
      if errors.any?
        flash[:error] = errors.to_json
      end

      redirect_to cards_path
    end

    def destroy
      @card.destroy
      redirect_to cards_path, notice: "Карта с номером #{@card.number} успешно удалена"
    end

    def block
      if @card.active?
        @card.blocked!
        render json: true, status: 200
      else
        render json: 'Заблокировать можно только активированную карту', status: 422
      end
    end

    def unblock
      if @card.blocked?
        @card.active!
        render json: true, status: 200
      else
        render json: "Карта #{@card.number} не заблокирована", status: 422
      end
    end

    private

    def set_card
      @card = Card.find_by(number: params[:number])
    end
  end
end
