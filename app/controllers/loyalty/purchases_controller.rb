module Loyalty
  class PurchasesController < ApplicationController
    skip_authorization_here

    def index
      if request.xhr?
        order_column = params[:sortName] || 'created_at'
        order_direction = params[:sortOrder].to_sym || :desc

        @purchases = Purchase.registered.order(order_column => order_direction).joins(:pharmacy)
        if params[:filter].present?
          filter = JSON.parse(params[:filter], symbolize_names: true)
          query = []

          if filter[:kind].present?
            query << "is_return = #{filter[:kind] == 'Возврат' ? 1 : 0}"
          end

          if filter[:pharmacy_name].present?
            query << "pharmacies.name like '%#{filter[:pharmacy_name]}%'"
          end

          @purchases =  @purchases.where(query.join(' AND '))
        end
        total = @purchases.count
        @purchases = @purchases.page(params[:pageNumber]).per(params[:pageSize]).preload(:card, :pharmacy, purchase_positions: :product)
        @purchases = @purchases.map do |purchase|
          {
            kind: purchase.is_return ? 'Возврат' : 'Продажа',
            created_at: I18n.l(purchase.created_at),
            pharmacy_name: purchase.pharmacy_name,
            sum: purchase.sum,
            card_number: purchase.card_number,
            card_balance: purchase.card_balance
          }
        end

        render json: { total: total, rows: @purchases }
      else
        @purchases = []
      end
    end
  end
end
