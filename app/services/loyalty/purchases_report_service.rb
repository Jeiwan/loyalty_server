module Loyalty
  class PurchasesReportService < ReportService
    def initialize(file_name, since = 24.hours.ago, till = Time.zone.now)
      initialize_vars(file_name)
      @since = since
      @till = till
      compile
    end

    private

    def compile
      title = 'Отчет по программе лояльности «Семейная копилка»'
      title << " за период с #{I18n.l(@since)} по #{I18n.l(@till)}."
      title << " Продажи"
      set_title title
      set_header ['Штрихкод карты СК', 'Чек, дата чека', 'Состав чека', 'АО', 'Код АО', 'Касса', 'ФИО СПС']
      collect_data.each do |cells|
        add_row cells
      end
    end

    def collect_data
      cards = Purchase.sells.registered.where('created_at > ? AND created_at < ?', @since, @till)
        .group(:card_number)
        .having('COUNT(card_number) >= 3')
        .pluck(:card_number)

      Purchase.sells.registered.where('created_at > ? AND created_at < ?', @since, @till)
        .where(card_number: cards)
        .includes({ purchase_positions: :product }, :pharmacy, { receipt: { cashbox_operation: :user } })
        .order(card_number: :asc, created_at: :asc).map do |purchase|
        last_operation = purchase.try(:receipt).try(:cashbox_operation)
        [
          purchase.card_number,
          "№#{last_operation.try(:number) || ' не определен'}, #{I18n.l(purchase.created_at)}",
          purchase.purchase_positions.map { |pp| "#{pp.product_name}, #{pp.quantity} шт." }.join("\n"),
          purchase.pharmacy_name,
          purchase.pharmacy_code,
          purchase.cashbox,
          last_operation.try(:user).try(:name)
        ]
      end
    end
  end
end
