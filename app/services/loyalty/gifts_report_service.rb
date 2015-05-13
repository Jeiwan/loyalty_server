module Loyalty
  class GiftsReportService < ReportService
    def initialize(file_name, since = 1.week.ago, till = Time.zone.now)
      initialize_vars(file_name)
      @since = since
      @till = till
      compile
    end

    private

    def compile
      title = 'Отчет по программе лояльности «Семейная копилка»'
      title << " за период с #{I18n.l(@since)} по #{I18n.l(@till)}."
      title << ' Подарки'
      set_title title
      set_header ['Штрихкод карты СК', 'Чек, по которому был выдан подарок', 'Подарок', 'АО', 'Код АО', 'ФИО СПС']
      collect_data.each do |cells|
        add_row cells
      end

      create_sheet({ name: 'Итого' })
      set_title "Итого с #{I18n.l(@since)} по #{I18n.l(@till)} выдано подарков:"
      set_header ['Наименование подарка', 'Категория', 'Количество']
      collect_summary.each do |cells|
        add_row cells
      end
    end

    def collect_data
      all_gifts = GiftPosition.pluck(:product_uuid)

      PurchasePosition.where(product_uuid: all_gifts).joins(:purchase)
        .where('loyalty_purchases.paid_by_bonus > 0 AND loyalty_purchases.created_at > ? AND loyalty_purchases.created_at < ?', @since, @till)
        .includes(purchase: { receipt: :cashbox_operation }).order('loyalty_purchases.created_at DESC').map do |gift|
        purchase = gift.purchase
        last_operation = purchase.try(:receipt).try(:cashbox_operation)
        [
          purchase.card_number,
          "№#{last_operation.try(:number) || ' не определен'}, #{I18n.l(purchase.created_at)}",
          purchase.find_gift.product_name,
          purchase.pharmacy_name,
          purchase.pharmacy_code,
          last_operation.try(:user).try(:name)
        ]
      end
    end

    def collect_summary
      all_gifts = GiftPosition.pluck(:product_uuid)
      PurchasePosition.where(product_uuid: all_gifts).joins(:purchase)
        .where('loyalty_purchases.paid_by_bonus > 0 AND loyalty_purchases.created_at > ? AND loyalty_purchases.created_at < ?', @since, @till)
        .group(:product_uuid)
        .select('product_uuid, COUNT(loyalty_purchases.uuid) AS purchases')
        .order('purchases DESC').map do |gift_sell|
        [
          gift_sell.product_name,
          gift_sell.gift_position.gift_category_number,
          gift_sell.purchases
        ]
      end
    end
  end
end
