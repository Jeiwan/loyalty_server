require 'rails_helper'

module Loyalty
  RSpec.describe Api::CardsCertificatesController, type: :controller do
    routes { Loyalty::Engine.routes }
    let!(:pharmacy) { create(:pharmacy) }

    describe 'GET #check' do
      context 'when card number is provided' do
        context 'when card exists' do
          it_behaves_like "a card balance check", :check
        end
      end

      context 'when certificate number is provided' do
        context 'when certificate exists' do
          let!(:certificate) { create(:loyalty_certificate, number: 5678, status: 0) }

          context 'when certificate is used' do
            before do
              certificate.used!
            end

            it 'returns error' do
              get :check, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Сертификат уже был использован'
            end
          end

          context 'when certificate is active' do
            before do
              certificate.active!
            end

            it 'returns true' do
              get :check, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq(certificate: { number: '5678' })
            end
          end
        end
      end

      context 'when wrong number provided' do
        it 'returns error' do
          get :check, number: '1234', format: :json,
            pharmacy_credentials: pharmacy.single_access_token
          expect(json[:response]).to eq 'Карта или сертификат не найдены'
        end
      end
    end
  end
end
