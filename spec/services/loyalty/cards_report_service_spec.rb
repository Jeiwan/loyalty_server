require 'rails_helper'

module Loyalty
  RSpec.describe CardsReportService do
    SHEET_FILE = Rails.root.join('tmp/cards_report.xls')
    subject { CardsReportService.new(SHEET_FILE) }

    context 'when there there is a card within the range' do
      let!(:card1) { create(:loyalty_card) }
      let!(:card2) { create(:loyalty_card, number: '3333') }
      let!(:pharmacy) { create(:pharmacy) }
      let!(:product1) { create(:product, name: 'Product1') }
      let!(:product2) { create(:product, name: 'Product2') }
      let!(:purchase1) do
        create(:loyalty_purchase, card: card1, sum: 17000, pharmacy: pharmacy, user_id: 1)
      end

      let!(:purchase1_position) do
        create(
          :loyalty_purchase_position,
          product: product1,
          purchase: purchase1,
          price: 17000,
          quantity: 1,
          sum: 17000
        )
      end

      let!(:purchase2) do
        create(:loyalty_purchase, card: card2, sum: 16000, pharmacy: pharmacy, user_id: 2)
      end

      let!(:purchase2_position) do
        create(
          :loyalty_purchase_position,
          product: product1,
          purchase: purchase2,
          price: 17000,
          quantity: 1,
          sum: 17000
        )
      end

      let!(:purchase3) do
        create(:loyalty_purchase, card: card1, sum: 700, pharmacy: pharmacy, user_id: 1)
      end

      let!(:purchase3_position) do
        create(
          :loyalty_purchase_position,
          product: product1,
          purchase: purchase3,
          price: 700,
          quantity: 1,
          sum: 700
        )
      end

      let!(:purchase4) do
        create(:loyalty_purchase, card: card2, sum: 900, pharmacy: pharmacy, user_id: 3)
      end

      let!(:purchase4_position) do
        create(
          :loyalty_purchase_position,
          product: product2,
          purchase: purchase4,
          price: 900,
          quantity: 1,
          sum: 900
        )
      end

      let!(:purchase5) do
        create(:loyalty_purchase, card: card2, sum: 900, pharmacy: pharmacy, user_id: 4)
      end

      let!(:purchase5_position) do
        create(
          :loyalty_purchase_position,
          product: product2,
          purchase: purchase5,
          price: 900,
          quantity: 1,
          sum: 900
        )
      end

      before do
        purchase1.commit!
        purchase2.commit!
        purchase3.commit!
        purchase4.commit!
        purchase5.commit!
      end

      it 'writes the card to the report' do
        subject.save
        report = SpreadsheetParser.parse_report(SHEET_FILE, :cards)
        expect(report.size).to eq 1
        expect(report[0][:card]).to eq card1.number
        expect(report[0][:balance]).to eq card1.balance
        expect(report[0][:receipt]).to match "№#{purchase3.receipt.cashbox_operation.number},"
        expect(report[0][:pharmacy]).to eq purchase3.pharmacy_name
        expect(report[0][:pharmacy_code]).to eq purchase3.pharmacy_code
        expect(report[0][:user]).to eq purchase3.receipt.cashbox_operation.user.name
      end
    end
  end
end
