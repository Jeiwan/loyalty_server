module Loyalty
  class ReportMailer < ActionMailer::Base
    default from: 'no-reply@drugstores.ru', reply_to: Settings.client.support_email || 'no-reply@drugstores.ru'

    def purchases_report(email, since = 24.hours.ago, till = Time.zone.now)
      file_name = "Семейная_копилка_Продажи_#{date_stamp}.xls"
      path = Rails.root.join("tmp/#{file_name}")
      Loyalty::PurchasesReportService.new(path, since, till).save

      attachments[file_name] = File.read(path)
      File.delete(path)
      mail(to: email, subject: 'Отчет по программе лояльности «Семейная копилка». Продажи') do |f|
        f.text do
          render text: 'Отчет по продажам: 3 и более продажи с одной карты за последние сутки'
        end
      end
    end

    def cards_report(email, since = 1.week.ago, till = Time.zone.now)
      file_name = "Семейная_копилка_Карты_#{date_stamp}.xls"
      path = Rails.root.join("tmp/#{file_name}")
      Loyalty::CardsReportService.new(path, since, till).save

      attachments[file_name] = File.read(path)
      File.delete(path)
      mail(to: email, subject: 'Отчет по программе лояльности «Семейная копилка». Карты') do |f|
        f.text do
          render text: 'Отчет по картам: сумма накомплений с 17 500 до 17 900, количество СПС работающих с картой СК - 1, 2. Период - последняя неделя'
        end
      end
    end

    def gifts_report(email, since = 1.week.ago, till = Time.zone.now)
      file_name = "Семейная_копилка_Подарки_#{date_stamp}.xls"
      path = Rails.root.join("tmp/#{file_name}")
      Loyalty::GiftsReportService.new(path, since, till).save

      attachments[file_name] = File.read(path)
      File.delete(path)
      mail(to: email, subject: 'Отчет по программе лояльности «Семейная копилка». Подарки') do |f|
        f.text do
          render text: 'Отчет по подаркам: выданные подарки за последнюю неделю'
        end
      end
    end

    private

    def date_stamp
      Date.today.strftime('%Y_%m_%d')
    end
  end
end
