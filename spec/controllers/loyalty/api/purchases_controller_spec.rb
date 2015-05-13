require 'rails_helper'

module Loyalty
  RSpec.describe Api::PurchasesController, type: :controller do
    routes { Loyalty::Engine.routes }
    let!(:pharmacy) { create(:pharmacy) }

    describe 'POST #create' do
      let!(:gift_product) { create(:product, name: 'Gift', uuid: '987654321') }
      let!(:gift_product2) { create(:product, name: 'Gift2', uuid: '123123123') }
      let!(:product) { create(:product) }
      let(:purchase_params) do
        {
          card_number: 1234,
          pharmacy_uuid: 'ea04a06a-9b77-11e2-9903-f23c91df23bd',
          sum: 1000.0,
          paid_by_bonus: 0,
          cashbox: 'testCashbox',
          receipt_uuid: 'cf42c57e-f95b-11e4-9f73-10ddb1fffe5b',
          purchase_positions_attributes: [
            {
              product_uuid: product.uuid,
              quantity: 1,
              price: 1000.0,
              sum: 1000.0
            }
          ],
          is_return: false
        }
      end

      context 'when all parameters are provided' do
        context 'when card exists' do
          let!(:card) { create(:loyalty_card, number: 1234, status: 1) }

          context 'when card is active' do
            context 'when receipt uuid is unique within the day' do
              context 'when purchase is paid by bonus' do
                context 'when purchase has a gift' do
                  before do
                    purchase_params[:purchase_positions_attributes].push(
                      {
                        product_uuid: gift_product.uuid,
                        quantity: 1,
                        price: 9.0,
                        sum: 9.0
                      }
                    )
                    card.transactions.create(kind: 0, sum: 1000)
                  end

                  context 'when there are gifts available' do
                    let!(:gift) { create(:loyalty_gift) }
                    let!(:gift2) { create(:loyalty_gift) }
                    let!(:gift_category) { create(:loyalty_gift_category, gift: gift) }
                    let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: gift_product) }
                    let!(:gift_category2) { create(:loyalty_gift_category, gift: gift2, threshold: 2000, number: 2) }
                    let!(:gift_position2) { create(:loyalty_gift_position, gift: gift2, gift_category: gift_category2, product: gift_product2) }

                    context 'when gift validation is correct' do
                      before do
                        purchase_params[:paid_by_bonus] = Purchase.validate_gift(purchase_params)
                        post :create, format: :json, purchase: purchase_params,
                          pharmacy_credentials: pharmacy.single_access_token
                      end

                      it 'returns purchase result' do
                        result = { bonuses_added: 1000.0, bonuses_removed: 9.0, status: 'deactivated', balance: 1991.0}
                        result[:gift_taken] = 1
                        result[:new_card_threshold] = Settings.loyalty.family_money_box.charge_threshold

                        expect(json[:response]).to eq(result)
                      end

                      it "sets purchase's paid_by_bonus" do
                        expect(Purchase.first.paid_by_bonus).to eq 9.0
                      end
                    end

                    context 'when there are two or more gifts in the purchase' do
                      before do
                        purchase_params[:paid_by_bonus] = Purchase.validate_gift(purchase_params)
                        purchase_params[:purchase_positions_attributes][0][:product_uuid] = gift_product.uuid
                        post :create, format: :json, purchase: purchase_params,
                          pharmacy_credentials: pharmacy.single_access_token
                      end

                      it 'return an error' do
                        expect(json[:response]).to eq 'В чеке может быть только один подарок'
                      end
                    end

                    context "when gift's amount is more that 1" do
                      before do
                        purchase_params[:paid_by_bonus] = Purchase.validate_gift(purchase_params)
                        purchase_params[:purchase_positions_attributes][1][:quantity] = 2
                        post :create, format: :json, purchase: purchase_params,
                          pharmacy_credentials: pharmacy.single_access_token
                      end

                      it 'returns an error' do
                        expect(json[:response]).to eq 'Подарок должен быть в количестве 1 штуки'
                      end
                    end

                    context "when paid_by_bonus and gift's price do not match" do
                      before do
                        purchase_params[:paid_by_bonus] = gift_position.price / 2
                        post :create, format: :json, purchase: purchase_params,
                          pharmacy_credentials: pharmacy.single_access_token
                      end
                    end
                  end

                  context 'when there are no gifts available' do
                    before do
                      purchase_params[:paid_by_bonus] = 100.0
                      post :create, format: :json, purchase: purchase_params,
                        pharmacy_credentials: pharmacy.single_access_token
                    end

                    it 'returns an error' do
                      expect(json[:response]).to eq 'Нет доступных подарков для данной карты'
                    end
                  end
                end

                context 'when pruchase has no gifts' do
                  context 'when there are gifts available' do
                    let!(:gift) { create(:loyalty_gift) }
                    let!(:gift2) { create(:loyalty_gift) }
                    let!(:gift_category) { create(:loyalty_gift_category, gift: gift) }
                    let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: gift_product) }
                    let!(:gift_category2) { create(:loyalty_gift_category, gift: gift2, threshold: 1337, number: 2) }
                    let!(:gift_position2) { create(:loyalty_gift_position, gift: gift2, gift_category: gift_category2, product: gift_product2) }

                    context 'when gift validation is correct' do
                      before do
                        purchase_params[:paid_by_bonus] = Purchase.validate_gift(purchase_params)
                        post :create, format: :json, purchase: purchase_params,
                          pharmacy_credentials: pharmacy.single_access_token
                      end

                      it 'returns purchase result' do
                        result = { bonuses_added: 1000.0, bonuses_removed: 0.0, status: 'active', balance: 1000.0}
                        result[:gifts] = [
                          {
                            category: 1,
                            gifts: [
                              { product_uuid: gift_product.uuid }
                            ]
                          }
                        ]
                        result[:left_till_next_gift] = 337.0

                        expect(json[:response]).to eq(result)
                      end
                    end
                  end
                end
              end

              context 'when purchase is not paid by bonus' do
                context 'when charge is possible' do
                  it 'returns purchase result' do
                    post :create, format: :json, purchase: purchase_params,
                      pharmacy_credentials: pharmacy.single_access_token
                    expect(json[:response]).to eq({ bonuses_added: 1000.0, bonuses_removed: 0.0, status: 'active', balance: 1000.0 })
                  end
                end

                context 'when charge is not possible' do
                  it 'returns purchase result' do
                    purchase_params[:sum] = Settings.loyalty.family_money_box.charge_threshold - 1
                    post :create, format: :json, purchase: purchase_params,
                      pharmacy_credentials: pharmacy.single_access_token
                    expect(json[:response]).to eq({ bonuses_added: 0.0, bonuses_removed: 0.0, status: 'active', balance: 0.0 })
                  end
                end
              end
            end
          end

          context 'when card is inactive' do
            before do
              card.inactive!
            end

            it 'returns an error' do
              post :create, format: :json, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Карта не активирована'
            end
          end
        end

        context 'when card does not exist' do
          it 'returns an error' do
            post :create, format: :json, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Карта не найдена'
          end
        end
      end

      context 'when some parameters are missing' do
        let!(:card) { create(:loyalty_card, number: 1234, status: 1) }

        context 'when receipt_uuid is not provided' do
          it 'returns an error' do
            post :create, format: :json, purchase: purchase_params.merge(receipt_uuid: nil),
              pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Не указан номер чека'
          end
        end

        %w(sum cashbox pharmacy_uuid).each do |field|
          context "when #{field} is not provided" do
            it 'returns an error' do
              post :create, format: :json, purchase: purchase_params.merge(field.to_sym => nil),
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to match "can't be blank"
            end
          end
        end
      end

      context 'when certificate is in gifts' do
        let!(:card) { create(:loyalty_card, number: 1234, status: 1) }
        let!(:transaction) { create(:loyalty_transaction, kind: 0, card: card, sum: 500) }
        let!(:certificate) { create(:loyalty_certificate, number: 5678, pin_code: 5555) }
        let!(:certificate_product) { create(:product, uuid: Settings.loyalty.family_money_box.certificate_uuid, name: 'Certificate') }
        let!(:gift) { create(:loyalty_gift) }
        let!(:gift_category) { create(:loyalty_gift_category, gift: gift, threshold: 500) }
        let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: certificate_product) }

        context 'when card has enough balance for the certificate' do
          context 'certificate is initiated' do
            before do
              certificate.initiated!
              purchase_params[:purchase_positions_attributes][0][:product_uuid] = certificate_product.uuid
              purchase_params[:purchase_positions_attributes][0][:price] = 6.0
              purchase_params[:purchase_positions_attributes][0][:sum] = 6.0
              purchase_params[:sum] = 6.0
              purchase_params[:paid_by_bonus] = 5.99
              purchase_params[:certificate] = certificate.number
              purchase_params[:pin_code] = certificate.pin_code

              post :create, purchase: purchase_params, format: :json,
                pharmacy_credentials: pharmacy.single_access_token
            end

            it 'returns result' do
              expect(json[:response]).to eq({ balance: 494.01, bonuses_added: 0.0, bonuses_removed: 5.99, certificate_sum: 2000, gift_taken: 1, new_card_threshold: 500, status: 'deactivated' })
            end

            it 'assigns the card to the certificate' do
              expect(certificate.reload.card_number).to eq card.number
            end

            it 'activates the certificate' do
              expect(certificate.reload.status).to eq 'active'
            end
          end
        end
      end

      context 'when paid by certificate' do
        let!(:certificate) { create(:loyalty_certificate, number: 1234, pin_code: 5555) }

        context 'when certificate is initiated' do
          before do
            certificate.initiated!
            purchase_params[:card_number] = nil
            purchase_params[:certificate] = certificate.number
            purchase_params[:pin_code] = certificate.pin_code
            purchase_params[:paid_by_bonus] = 999.99
            purchase_params[:sum] = 0.01
            post :create, purchase: purchase_params, format: :json, pharmacy_credentials: pharmacy.single_access_token
          end

          it 'returns result' do
            expect(json[:response]).to eq({ bonuses_removed: 999.99, new_card_threshold: 500, certificate_number: certificate.number, status: 'used' })
          end

          it 'deactivates the certificate' do
            expect(certificate.reload.status).to eq 'used'
          end

          it 'assigns the purchase to the certificate' do
            expect(certificate.reload.purchase).to be_present
          end
        end
      end
    end

    describe 'PUT #commit' do
      it 'always returns true' do
        put :commit, pharmacy_credentials: pharmacy.single_access_token, format: :json
        expect(json).to eq(status: 0, response: true)
      end
    end

    describe 'PUT #rollback' do
      let!(:card) { create(:loyalty_card, status: 1) }

      context 'when all parameters are provided' do
        context 'when the purchase exists' do
          let!(:purchase) { create(:loyalty_purchase, card: card, status: 1) }

          context "when the purchase's state is 'initiated'" do
            it 'returns true' do
              purchase_params = {
                card_number: purchase.card_number,
                cashbox: purchase.cashbox,
                receipt_uuid: purchase.receipt_uuid,
                is_return: false
              }

              put :rollback, format: :json, purchase: purchase_params,
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq true
            end
          end
        end
      end

      context 'when some paratemers are missing' do
        context 'when card_number is missing' do
          it 'returns an error' do
            purchase_params = {
              cashbox: 'testCashbox',
              receipt_uuid: '1234',
              is_return: false
            }

            put :rollback, format: :json, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Не указан номер карты'
          end
        end

        context 'when cashbox is missing' do
          it 'returns an error' do
            purchase_params = {
              card_number: card.number,
              receipt_uuid: '1234',
              is_return: false
            }

            put :rollback, format: :json, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Не указана касса'
          end
        end

        context 'when receipt_uuid is missing' do
          it 'returns an error' do
            purchase_params = {
              card_number: card.number,
              cashbox: 'testCashbox',
              is_return: false
            }

            put :rollback, format: :json, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Не указан номер чека'
          end
        end
      end
    end

    describe 'GET #demand_gift' do
      let!(:gift_product) { create(:product, name: 'Gift', uuid: '987654321') }
      let!(:product) { create(:product) }
      let!(:purchase_params) do
        {
          card_number: 1234,
          pharmacy_uuid: 'ea04a06a-9b77-11e2-9903-f23c91df23bd',
          sum: 9.0,
          paid_by_bonus: 5.0,
          cashbox: 'testCashbox',
          receipt_uuid: 'cf42c57e-f95b-11e4-9f73-10ddb1fffe5b',
          purchase_positions_attributes: [
            {
              product_uuid: gift_product.uuid,
              quantity: 1,
              price: 9.0,
              sum: 9.0
            }
          ],
          is_return: false
        }
      end

      context 'when card exists' do
        let!(:card) { create(:loyalty_card, number: '1234', status: 1) }

        context 'when card is active' do
          context 'when there is a gift available' do
            let!(:gift) { create(:loyalty_gift) }
            let!(:gift_category) { create(:loyalty_gift_category, gift: gift) }
            let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: gift_product) }

            before do
              card.update(balance: gift_category.threshold)
            end

            context 'when there is only one position in the purchase' do
              it "returns gift's price - 0.01" do
                get :demand_gift, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token, format: :json
                expect(json[:response]).to eq(purchase_params[:purchase_positions_attributes][0][:price] - 0.01)
              end
            end

            context 'when there are one or more positions in the purchase' do
              before do
                purchase_params[:purchase_positions_attributes].push(
                  {
                    product_uuid: product.uuid,
                    quantity: 1,
                    price: 9.0,
                    sum: 9.0
                  }
                )
              end

              it "returns gift's full price" do
                get :demand_gift, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token, format: :json
                expect(json[:response]).to eq(purchase_params[:purchase_positions_attributes][0][:price])
              end
            end

            context 'when there are two or more gifts in the purchase' do
              before do
                purchase_params[:purchase_positions_attributes].push(
                  {
                    product_uuid: gift_product.uuid,
                    quantity: 1,
                    price: 9.0,
                    sum: 9.0
                  }
                )
              end

              it 'returns error' do
                get :demand_gift, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token, format: :json
                expect(json[:response]).to eq 'В чеке может быть только один подарок'
              end
            end

            context "when gift's amount is two or more" do
              before do
                purchase_params[:purchase_positions_attributes][0][:quantity] = 2
              end

              it 'returns error' do
                get :demand_gift, purchase: purchase_params, pharmacy_credentials: pharmacy.single_access_token, format: :json
                expect(json[:response]).to eq 'Подарок должен быть в количестве 1 штуки'
              end
            end
          end
        end
      end
    end

    describe 'GET #check_threshold' do
      context 'when sum is provided' do
        context 'when sum is greater than the threshold' do
          it 'returns true' do
            get :check_threshold, format: :json, sum: Settings.loyalty.family_money_box.charge_threshold + 1,
              pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq true
          end
        end

        context 'when sum is less than the threshold' do
          it 'returns false' do
            get :check_threshold, format: :json, sum: Settings.loyalty.family_money_box.charge_threshold - 1,
              pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq false
          end
        end
      end

      context 'when sum is not provided' do
        it 'returns an error' do
          get :check_threshold, format: :json, pharmacy_credentials: pharmacy.single_access_token
          expect(json[:response]).to eq 'Не указана сумма чека'
        end
      end
    end
  end
end
