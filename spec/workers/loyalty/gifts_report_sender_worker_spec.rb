require 'rails_helper'

describe Loyalty::GiftsReportSenderWorker do
  subject { described_class.new }

  after do
    ActionMailer::Base.deliveries.clear
  end

  context 'when it is 8:00 am' do
    before do
      Timecop.freeze(Time.new(2015, 7, 7, 11, 0))
    end

    after do
      Timecop.return
    end

    context 'when client is farmaimpex' do
      before do
        Settings.client = OpenStruct.new({ name: 'Farmaimpex' })
      end

      let(:mail) { subject.perform }

      it 'sends an email' do
        expect(mail.to).to eq ['test@test.test']
        expect(mail.subject).to eq(
          'Отчет по программе лояльности «Семейная копилка». Подарки'
        )
        expect(mail.attachments.count).to eq 1
        expect(ActionMailer::Base.deliveries.count).to eq 1
      end
    end

    context 'when client is not farmaimpex' do
      before do
        Settings.client = OpenStruct.new({ name: 'A5' })
      end

      let(:mail) { subject.perform }

      it 'does nothing' do
        expect(mail).to be_nil
      end
    end
  end

  context 'when it is not 8:00 am' do
    let(:mail) { subject.perform }

    it 'returns nil' do
      Timecop.freeze(Time.new(2015, 7, 7, 20, 23)) do
        expect(mail).to be_nil
      end
    end
  end
end
