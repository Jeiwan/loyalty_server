require 'rails_helper'

module Loyalty
  RSpec.describe PurchasesReportService do
    SHEET_FILE = Rails.root.join('tmp/purchases_report.xls')
    subject { PurchasesReportService.new(SHEET_FILE) }

    let!(:card1) { create(:loyalty_card) }
    let!(:card2) { create(:loyalty_card, number: '3333') }
    let!(:card3) { create(:loyalty_card, number: '54321') }
    let!(:pharmacy) { create(:pharmacy) }
    let!(:product1) { create(:product, name: 'Product1') }
    let!(:product2) { create(:product, name: 'Product2') }
    let!(:purchase0) { create(:loyalty_purchase, card: card3, sum: 200, pharmacy: pharmacy, created_at: 25.hours.ago) }
    let!(:purchase0_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase0, price: 200, quantity: 1, sum: 200, created_at: 25.hours.ago) }

    before do
      purchase0.commit!
    end

    context 'when there are purchases made within the last 24 hours' do
      let!(:purchase1) { create(:loyalty_purchase, card: card1, sum: 17700, pharmacy: pharmacy) }
      let!(:purchase1_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase1, price: 17700, quantity: 1, sum: 17700) }
      let!(:purchase2) { create(:loyalty_purchase, card: card2, sum: 17400, pharmacy: pharmacy) }
      let!(:purchase2_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase2, price: 17400, quantity: 1, sum: 17400) }
      let!(:purchase3) { create(:loyalty_purchase, card: card1, sum: 17700, pharmacy: pharmacy) }
      let!(:purchase3_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase3, price: 17700, quantity: 1, sum: 17700) }
      let!(:purchase4) { create(:loyalty_purchase, card: card1, sum: 17700, pharmacy: pharmacy) }
      let!(:purchase4_position1) { create(:loyalty_purchase_position, product: product1, purchase: purchase4, price: 17500, quantity: 1, sum: 17500) }
      let!(:purchase4_position2) { create(:loyalty_purchase_position, product: product2, purchase: purchase4, price: 200, quantity: 1, sum: 200) }

      before do
        purchase1.commit!
        purchase2.commit!
        purchase3.commit!
        purchase4.commit!
      end

      it 'writes the purchases to the report' do
        subject.save
        report = SpreadsheetParser.parse_report(SHEET_FILE, :purchases)
        expect(report.size).to eq 3
        expect(report[0][:card]).to eq card1.number
        expect(report[0][:receipt]).to match "№#{purchase1.receipt.cashbox_operation.number},"
        expect(report[0][:positions]).to match purchase1_position.product_name
        expect(report[0][:pharmacy]).to eq purchase1.pharmacy_name
        expect(report[0][:pharmacy_code]).to eq purchase1.pharmacy_code
        expect(report[0][:cashbox]).to eq purchase1.cashbox
        expect(report[0][:user]).to eq purchase1.receipt.cashbox_operation.user.name

        expect(report[1][:card]).to eq card1.number
        expect(report[1][:receipt]).to match "№#{purchase3.receipt.cashbox_operation.number},"
        expect(report[1][:positions]).to match purchase3_position.product_name
        expect(report[1][:pharmacy]).to eq purchase3.pharmacy_name
        expect(report[1][:pharmacy_code]).to eq purchase3.pharmacy_code
        expect(report[1][:cashbox]).to eq purchase3.cashbox
        expect(report[1][:user]).to eq purchase3.receipt.cashbox_operation.user.name

        expect(report[2][:card]).to eq card1.number
        expect(report[2][:receipt]).to match "№#{purchase4.receipt.cashbox_operation.number},"
        expect(report[2][:positions]).to match purchase4_position1.product_name
        expect(report[2][:positions]).to match purchase4_position2.product_name
        expect(report[2][:pharmacy]).to eq purchase4.pharmacy_name
        expect(report[2][:pharmacy_code]).to eq purchase4.pharmacy_code
        expect(report[2][:cashbox]).to eq purchase4.cashbox
        expect(report[2][:user]).to eq purchase4.receipt.cashbox_operation.user.name
      end
    end
  end
end
