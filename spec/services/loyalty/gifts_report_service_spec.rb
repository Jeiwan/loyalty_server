require 'rails_helper'

module Loyalty
  RSpec.describe GiftsReportService do
    SHEET_FILE = Rails.root.join('tmp/gifts_report.xls')
    subject { GiftsReportService.new(SHEET_FILE) }

    let!(:card1) { create(:loyalty_card) }
    let!(:card2) { create(:loyalty_card, number: '3333') }
    let!(:card3) { create(:loyalty_card, number: '31337') }
    let!(:pharmacy) { create(:pharmacy) }
    let!(:product1) { create(:product, name: 'Product1') }
    let!(:product2) { create(:product, name: 'Product2') }
    let!(:gift_product) { create(:product, name: 'Gift') }
    let!(:gift_product2) { create(:product, name: 'SuperGift') }
    let!(:gift) { create(:loyalty_gift) }
    let!(:gift_category) { create(:loyalty_gift_category, number: 1, threshold: 100) }
    let!(:gift_position) { create(:loyalty_gift_position, product: gift_product, gift_category: gift_category) }
    let!(:gift_category2) { create(:loyalty_gift_category, number: 2, threshold: 200) }
    let!(:gift_posation2) { create(:loyalty_gift_position, product: gift_product2, gift_category: gift_category2) }

    let!(:purchase0) { create(:loyalty_purchase, card: card1, sum: 100, pharmacy: pharmacy, created_at: 8.days.ago) }
    let!(:purchase0_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase0, price: 100, quantity: 1, sum: 100) }
    let!(:purchase0_gift) { create(:loyalty_purchase_position, product: gift_product, purchase: purchase0, price: 10, quantity: 1, sum: 10) }

    context 'when gifts were taken in the last week' do
      let!(:purchase1) { create(:loyalty_purchase, card: card1, sum: 17700, pharmacy: pharmacy) }
      let!(:purchase1_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase1, price: 17700, quantity: 1, sum: 17700) }
      let!(:purchase1_gift) { create(:loyalty_purchase_position, product: gift_product, purchase: purchase1, price: 10, quantity: 1, sum: 10) }

      let!(:purchase2) { create(:loyalty_purchase, card: card2, sum: 17400, pharmacy: pharmacy) }
      let!(:purchase2_position) { create(:loyalty_purchase_position, product: product1, purchase: purchase2, price: 17400, quantity: 1, sum: 17400) }
      let!(:purchase2_gift) { create(:loyalty_purchase_position, product: gift_product, purchase: purchase2, price: 10, quantity: 1, sum: 10) }

      let!(:purchase3) { create(:loyalty_purchase, card: card3, sum: 17400, pharmacy: pharmacy) }
      let!(:purchase3_position) { create(:loyalty_purchase_position, product: product2, purchase: purchase3, price: 600, quantity: 1, sum: 600) }
      let!(:purchase3_gift) { create(:loyalty_purchase_position, product: gift_product2, purchase: purchase3, price: 10, quantity: 1, sum: 10) }

      before do
        purchase1.update(paid_by_bonus: 10.0)
        purchase2.update(paid_by_bonus: 10.0)
        purchase3.update(paid_by_bonus: 10.0)

        purchase1.commit!
        purchase2.commit!
        purchase3.commit!
      end

      it 'writes the card to the report' do
        subject.save
        report = SpreadsheetParser.parse_report(SHEET_FILE, :gifts)

        expect(report.size).to eq 3
        expect(report[0][:card]).to eq card3.number
        expect(report[0][:receipt]).to match "№#{purchase3.receipt.cashbox_operation.number},"
        expect(report[0][:gift]).to match gift_product2.name
        expect(report[0][:pharmacy]).to eq purchase3.pharmacy_name
        expect(report[0][:pharmacy_code]).to eq purchase3.pharmacy_code
        expect(report[0][:user]).to eq purchase3.receipt.cashbox_operation.user.name

        expect(report[1][:card]).to eq card2.number
        expect(report[1][:receipt]).to match "№#{purchase2.receipt.cashbox_operation.number},"
        expect(report[1][:gift]).to match gift_product.name
        expect(report[1][:pharmacy]).to eq purchase2.pharmacy_name
        expect(report[1][:pharmacy_code]).to eq purchase2.pharmacy_code
        expect(report[1][:user]).to eq purchase2.receipt.cashbox_operation.user.name

        expect(report[2][:card]).to eq card1.number
        expect(report[2][:receipt]).to match "№#{purchase1.receipt.cashbox_operation.number},"
        expect(report[2][:gift]).to match gift_product.name
        expect(report[2][:pharmacy]).to eq purchase1.pharmacy_name
        expect(report[2][:pharmacy_code]).to eq purchase1.pharmacy_code
        expect(report[2][:user]).to eq purchase1.receipt.cashbox_operation.user.name

        report = SpreadsheetParser.parse_report(SHEET_FILE, :gifts, 1)

        expect(report.size).to eq 2
        expect(report[0][:gift_name]).to eq gift_product.name
        expect(report[0][:category]).to eq gift_category.number
        expect(report[0][:quantity]).to eq 2

        expect(report[1][:gift_name]).to eq gift_product2.name
        expect(report[1][:category]).to eq gift_category2.number
        expect(report[1][:quantity]).to eq 1
      end
    end
  end
end
