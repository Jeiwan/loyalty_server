require 'rails_helper'

module Loyalty
  RSpec.describe Api::CertificatesController, type: :controller do
    routes { Loyalty::Engine.routes }
    let!(:pharmacy) { create(:pharmacy) }

    describe 'GET #check' do
      context 'when certificate number is provided' do
        context 'when certificate exists' do
          it_behaves_like "a certificate check", :check

          context 'when certificate is initiated' do
            let!(:certificate) { create(:loyalty_certificate, number: 5678, status: 1) }

            it 'returns certificate number' do
              get :check, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq(certificate: { number: certificate.number })
            end
          end
        end

        context 'when certificate does not exist' do
          it 'returns error' do
            get :check, number: 1234, format: :json, pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Сертификат не найден'
          end
        end
      end
    end

    describe 'GET #check_pin_code' do
      context 'when certificate number is provided' do
        context 'when certificate exists' do
          let!(:certificate) { create(:loyalty_certificate, number: 5678, pin_code: 5555, status: 0) }

          context 'when certificate is not active' do
            context 'when pin-code is provided' do
              context 'when pin-code is correct' do
                it 'returns true' do
                  get :check_pin_code, number: 5678, pin_code: 5555, format: :json,
                    pharmacy_credentials: pharmacy.single_access_token
                  expect(json[:response]).to eq true
                end
              end

              context 'when pin-code is incorrect' do
                it 'returns an error' do
                  get :check_pin_code, number: 5678, pin_code: 1010, format: :json,
                    pharmacy_credentials: pharmacy.single_access_token
                  expect(json[:response]).to eq 'Неверный пин-код'
                end
              end
            end

            context 'when pin-code is not provided' do
              it 'returns an error' do
                get :check_pin_code, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
                expect(json[:response]).to eq 'Не указан пин-код'
              end
            end
          end

          context 'when certificate is active' do
            before do
              certificate.active!
            end

            it 'returns an error' do
              get :check_pin_code, number: 5678, pin_code: 5555, format: :json,
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Сертификат уже активирован'
            end
          end

          context 'when certificate is used' do
            before do
              certificate.used!
            end

            it 'returns an error' do
              get :check_pin_code, number: 5678, pin_code: 5555, format: :json,
                pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Сертификат уже был использован'
            end
          end
        end

        context 'when certificate is not found' do
          it 'returns an error' do
            get :check_pin_code, number: 5678, pin_code: 5555, format: :json,
              pharmacy_credentials: pharmacy.single_access_token
            expect(json[:response]).to eq 'Сертификат не найден'
          end
        end
      end
    end

    describe 'GET #apply' do
      context 'when certificate is provided' do
        context 'when certificate exists' do
          let!(:certificate) { create(:loyalty_certificate, number: 5678, status: 2) }

          context 'when certificate is active' do
            it 'returns certificate discount' do
              get :apply, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq Settings.loyalty.family_money_box.certificate_sum
            end
          end

          context 'when certificate is inactive' do
            before do
              certificate.inactive!
            end

            it 'returns an error' do
              get :apply, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Сертификат не активирован'
            end
          end

          context 'when certificate is used' do
            before do
              certificate.used!
            end

            it 'returns an error' do
              get :apply, number: 5678, format: :json, pharmacy_credentials: pharmacy.single_access_token
              expect(json[:response]).to eq 'Сертификат уже был использован'
            end
          end

        end
      end
    end
  end
end
