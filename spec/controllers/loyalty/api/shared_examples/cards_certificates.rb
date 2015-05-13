RSpec.shared_examples "a card balance check" do |action|
  let!(:card) { create(:loyalty_card, number: 1234, balance: 12.34, status: 1) }

  context 'when gifts are available for the card' do
    let!(:gift) { create(:loyalty_gift) }
    let!(:product) { create(:product, name: 'Gift') }
    let!(:gift_category) { create(:loyalty_gift_category, gift: gift) }
    let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: product) }

    it "returns card's balance and the list of gifts" do
      gifts = [ { category: 1, gifts: [{ product_uuid: product.uuid }] } ]
      get action, number: 1234, format: :json, pharmacy_credentials: pharmacy.single_access_token
      json_response = action == :check ? json[:response][:card] : json[:response]
      expect(json_response).to eq({ balance: 12.34, gifts: gifts, number: card.number })
    end
  end

  context 'when gifts are not available for the card' do
    it "returns card's balance" do
      get action, number: 1234, format: :json, pharmacy_credentials: pharmacy.single_access_token
      json_response = action == :check ? json[:response][:card] : json[:response]
      expect(json_response).to eq({ balance: 12.34, number: card.number })
    end
  end
end

RSpec.shared_examples "a certificate check" do |action|
  let!(:certificate) { create(:loyalty_certificate, number: 5678, status: 0) }

  context 'when certificate is used' do
    before do
      certificate.used!
    end

    it 'returns error' do
      get action, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
      expect(json[:response]).to eq 'Сертификат уже был использован'
    end
  end

  context 'when certificate is active' do
    before do
      certificate.active!
    end

    it 'returns true' do
      get action, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
      expect(json[:response]).to eq 'Сертификат уже активирован'
    end
  end
end
