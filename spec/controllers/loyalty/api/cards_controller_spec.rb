require 'rails_helper'

module Loyalty
  RSpec.describe Api::CardsController, type: :controller do
    routes { Loyalty::Engine.routes }
    let!(:pharmacy) { create(:pharmacy) }

    describe 'GET #balance' do
      context 'when card exists' do
        it_behaves_like "a card balance check", :balance
      end

      context 'when card does not exist' do
        it 'returns error' do
          get :balance, number: 1234, pharmacy_credentials: pharmacy.single_access_token, format: :json
          expect(json[:response]).to eq 'Карта с таким номером не найдена'
        end
      end
    end

    describe 'PUT #activate' do
      context 'when card exists' do
        let!(:card) { create(:loyalty_card, number: 1234) }

        context 'when card is not active' do
          it 'activates the card' do
            put :activate, number: 1234, pharmacy_credentials: pharmacy.single_access_token, format: :json
            expect(json[:response]).to eq 'Карта успешно зарегистрирована'
          end
        end

        context 'when card is already active' do
          before do
            card.active!
          end

          it 'returns error' do
            put :activate, number: 1234, pharmacy_credentials: pharmacy.single_access_token, format: :json
            expect(json[:response]).to eq 'Карта уже активирована'
          end
        end
      end

      context 'when card does not exist' do
        it 'returns error' do
          put :activate, number: 1234, pharmacy_credentials: pharmacy.single_access_token, format: :json
          expect(json[:response]).to eq 'Карта с таким номером не найдена'
        end
      end
    end

    describe 'GET #check_for_return' do
      context 'when all parameters are provided' do
        let!(:card) { create(:loyalty_card, status: 1) }
        context 'when purchase was made before' do
          let!(:purchase) { create(:loyalty_purchase, status: 1) }

          context 'when purchase was made with provided card number' do
            before do
              purchase.update(card_number: card.number)
            end

            it 'returns true' do
              get :check_for_return, format: :json, number: card.number, receipt_uuid: purchase.receipt_uuid,
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq true
            end
          end

          context 'when purchase was made with different card' do
            it 'returns an error' do
              get :check_for_return, format: :json, number: card.number, receipt_uuid: purchase.receipt_uuid,
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Продажа была совершена по другой карте'
            end
          end
        end

        context 'when there were no purchase before' do
          it 'returns an error' do
            get :check_for_return, format: :json, number: card.number, receipt_uuid: '123123123',
              pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Продажа не найдена'
          end
        end
      end

      context 'when card number is wrong' do
        it 'returns error' do
          get :check_for_return, format: :json, number: 1234, receipt_uuid: '123123123',
            pharmacy_credentials: pharmacy.single_access_token
          expect(json[:response]).to eq 'Карта с таким номером не найдена'
        end
      end
    end
  end
end
