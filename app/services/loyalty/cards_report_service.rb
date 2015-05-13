module Loyalty
  class CardsReportService < ReportService
    MIN_BALANCE = 17500
    MAX_BALANCE = 17900

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
      title << " Карты"
      set_title title
      set_header ['Штрихкод карты СК', 'Сумма накоплений', 'Последний чек, дата', 'АО', 'Код АО', 'ФИО СПС']
      collect_data.each do |cells|
        add_row cells
      end
    end

    def collect_data
      cards = Card.where('balance >= ? AND balance <= ?', MIN_BALANCE, MAX_BALANCE).pluck(:number)
      cards = Purchase.where(card_number: cards).where('created_at > ? AND created_at < ?', @since, @till)
        .group([:card_number])
        .having("COUNT(user_id) IN (?)", [1, 2])
        .pluck(:card_number)

      Card.where(number: cards).includes(purchases: { receipt: :cashbox_operation }).order(balance: :desc).map do |card|
        last_purchase = card.purchases.last
        last_operation = last_purchase.try(:receipt).try(:cashbox_operation)

        [
          card.number,
          card.balance,
          "№#{last_operation.try(:number) || ' не определен'}, #{I18n.l(last_purchase.created_at)}",
          last_purchase.pharmacy_name,
          last_purchase.pharmacy_code,
          last_operation.try(:user).try(:name)
        ]
      end
    end
  end
end
