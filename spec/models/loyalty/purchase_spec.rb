require 'rails_helper'

module Loyalty
  describe Purchase, type: :model do
    describe '.register' do
      let!(:product) { create(:product) }
      let!(:card) { create(:loyalty_card, status: 1) }
      let!(:certificate) { create(:loyalty_certificate, status: 1) }
      let(:purchase_params) do
        {
          card_number: card.number,
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

      context 'purchase with card,' do
        context 'when card number is wrong' do
          it 'raises an error' do
            expect { Purchase.register(31337, nil, nil, false, purchase_params) }.to raise_error(
              'Карта не найдена'
            )
          end
        end

        context 'when card is inactive' do
          before do
            card.inactive!
          end

          it 'raises an error' do
            expect { Purchase.register(card.number, nil, nil, false, purchase_params) }.to raise_error(
              'Карта не активирована'
            )
          end
        end

        context 'when card is blocked' do
          before do
            card.blocked!
          end

          it 'raises an error' do
            expect { Purchase.register(card.number, nil, nil, false, purchase_params) }.to raise_error(
              'Карта заблокирована'
            )
          end
        end

        context 'when card number is correct' do
          it 'creates purchase' do
            expect { Purchase.register(card.number, nil, nil, false, purchase_params) }.to change(Purchase, :count).by(1)
          end
        end
      end

      context 'purchase with card and certificate (certificatea as a gift)' do
        context 'when pin code is not provided' do
          it 'raises an error' do
            expect do
              Purchase.register(card.number, certificate.number, nil, true, purchase_params)
            end.to raise_error(
              'Не указан пин-код'
            )
          end
        end

        context 'when certificate number is not provided' do
          it 'raises an error' do
            expect do
              Purchase.register(card.number, nil, nil, true, purchase_params)
            end.to raise_error(
              'Не указан номер сертификата'
            )
          end
        end

        context 'when pin code is wrong' do
          it 'raises an error' do
            expect do
              Purchase.register(card.number, certificate.number, 31337, true, purchase_params)
            end.to raise_error(
              'Неверный пин-код'
            )
          end
        end

        context 'when there is no certificate in receipt' do
          it 'raises an error' do
            expect do
              Purchase.register(card.number, certificate.number, certificate.pin_code, false, purchase_params)
            end.to raise_error(
              'В чеке отсутствует сертификат'
            )
          end
        end

        context 'when all parameters are correct' do
          before do
            Purchase.register(card.number, certificate.number, certificate.pin_code, true, purchase_params)
          end

          it 'creates a purchase' do
            expect(Purchase.count).to eq 1
          end

          it 'activates the certificate' do
            expect(certificate.reload.status).to eq 'active'
          end
        end
      end

      context 'purchase with certificate,' do
        context 'when certificate number is wrong' do
          it 'raises an error' do
            expect { Purchase.register(nil, 31337, nil, false, purchase_params) }.to raise_error(
              'Сертификат не найден'
            )
          end
        end

        context 'when certificate is inactive' do
          before do
            certificate.inactive!
          end

          it 'raises an error' do
            expect { Purchase.register(nil, certificate.number, nil, false, purchase_params) }.to raise_error(
              'Сертификат не активирован'
            )
          end
        end

        context 'when certificate is used' do
          before do
            certificate.used!
          end

          it 'raises an error' do
            expect { Purchase.register(nil, certificate.number, nil, false, purchase_params) }.to raise_error(
              'Сертификат уже был использован'
            )
          end
        end

        context 'when certificate number is correct' do
          it 'creates purchase' do
            expect { Purchase.register(nil, certificate.number, nil, false, purchase_params) }.to change(Purchase, :count).by(1)
          end
        end
      end

      context 'when card number and certificate number are not provided' do
        it 'raises an error' do
          expect { Purchase.register(nil, nil, nil, false, nil) }.to raise_error 'Не указан номер карты или сертификата'
        end
      end
    end

    describe '#commit!' do
      let!(:card) { create(:loyalty_card) }
      let!(:purchase) { create(:loyalty_purchase, card: card) }
      let!(:purchase_position) { create(:loyalty_purchase_position, purchase: purchase) }
      let!(:gift_product) { create(:product, name: 'Gift') }
      let!(:gift) { create(:loyalty_gift) }
      let!(:gift_category) { create(:loyalty_gift_category, number: 1, threshold: 0) }
      let!(:gift_position) { create(:loyalty_gift_position, gift: gift, gift_category: gift_category, product: gift_product) }

      context 'when purchase is already registered' do
        before do
          purchase.commit!
        end

        it 'raises an error' do
          expect { purchase.commit! }.to raise_error 'Продажа уже подтверждена'
        end
      end

      context 'when purchase is cancelled' do
        before do
          purchase.cancelled!
        end

        it 'raises an error' do
          expect { purchase.commit! }.to raise_error 'Нельзя подтвердить отмененную продажу'
        end
      end

      context 'when purchase is correct,' do
        context 'when purchase was made with card' do
          context 'when purchase has gift' do
            let!(:gift_position) { create(:loyalty_purchase_position, purchase: purchase, product: gift_product) }

            before do
              purchase.update(paid_by_bonus: gift_position.sum)
              purchase.commit!
            end

            it 'discharges gift sum' do
              expect(card.reload.balance).to eq 0 - gift_position.sum
            end

            it 'creates discharge transaction' do
              expect(purchase.transactions.discharge.count).to eq 1
            end

            specify 'discharge transaction sum equals to gift price' do
              expect(purchase.transactions.first.sum).to eq purchase.paid_by_bonus
            end
          end

          context 'when purchase has no gifts' do
            context 'when charge is possible' do
              before do
                purchase_position.update(price: 1000, sum: 1000)
                purchase.update(sum: 1000)
                purchase.commit!
              end

              it 'charges bonuses to the card' do
                expect(card.reload.balance).to eq purchase.sum
              end

              it 'creates charge transaction' do
                expect(purchase.transactions.charge.count).to eq 1
              end

              specify 'transaction sum is not 0' do
                expect(purchase.transactions.first.sum).to eq purchase.sum
              end
            end

            context 'when charge is not possible' do
              it 'does not charge bonuses to the card' do
                purchase.commit!
                expect(card.reload.balance).to eq 0
              end

              it 'does not create transactions' do
                expect { purchase.commit! }.not_to change(Transaction, :count)
              end
            end
          end
        end
      end
    end
  end
end
