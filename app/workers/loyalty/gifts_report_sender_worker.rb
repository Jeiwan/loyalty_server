module Loyalty
  class GiftsReportSenderWorker
    include Sidekiq::Worker

    def perform
      return unless correct_time?

      for_specific_client('farmaimpex') do
        emails = if Rails.env.production?
          [
            'email@for_reports.com'
          ].join(',')
        else
          'test@test.test'
        end
        Loyalty::ReportMailer.gifts_report(emails).deliver_now
      end
    end

    private

    # Should be started only at 8:00 am
    def correct_time?
      now = Time.zone.now
      now.hour == 8 && now.min < 5
    end

    def for_specific_client(*client_names)
      clients = client_names.map { |client| client.to_s.capitalize }

      yield if clients.include?(Settings.client.name) && block_given?
    end
  end
end
