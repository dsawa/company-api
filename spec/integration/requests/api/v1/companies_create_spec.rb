require 'rails_helper'

RSpec.describe 'Api::V1::Companies#create', type: :request do
  let(:headers) { { 'Accept': 'application/json' } }

  describe 'POST /api/v1/companies' do
    context 'when authenticated' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      context 'with valid parameters' do
        let(:valid_addresses_attributes) do
          [ FactoryBot.attributes_for(:address), FactoryBot.attributes_for(:address) ]
        end
        let(:valid_company_attributes) do
          { company: FactoryBot.attributes_for(:company).merge(addresses_attributes: valid_addresses_attributes) }
        end

        it 'creates a new company with addresses as in params' do
          expect(Company.count).to eq(0)
          expect(Address.count).to eq(0)

          post '/api/v1/companies', params: valid_company_attributes, headers: headers

          company = Company.first

          expect(company.name).to eq(valid_company_attributes[:company][:name])
          expect(company.registration_number).to eq(valid_company_attributes[:company][:registration_number])

          address_1 = company.addresses.first
          address_2 = company.addresses.last

          expect(address_1.street).to eq(valid_addresses_attributes[0][:street])
          expect(address_1.city).to eq(valid_addresses_attributes[0][:city])
          expect(address_1.postal_code).to eq(valid_addresses_attributes[0][:postal_code])
          expect(address_1.country).to eq(valid_addresses_attributes[0][:country])

          expect(address_2.street).to eq(valid_addresses_attributes[1][:street])
          expect(address_2.city).to eq(valid_addresses_attributes[1][:city])
          expect(address_2.postal_code).to eq(valid_addresses_attributes[1][:postal_code])
          expect(address_2.country).to eq(valid_addresses_attributes[1][:country])

          expect(Company.count).to eq(1)
          expect(Address.count).to eq(2)
        end

        it 'returns status code 201' do
          post '/api/v1/companies', params: valid_company_attributes, headers: headers

          expect(response).to have_http_status(:created)
        end

        it 'returns the created company with addresses' do
          post '/api/v1/companies', params: valid_company_attributes, headers: headers

          json_response = JSON.parse(response.body)

          expect(json_response['name']).to eq(valid_company_attributes[:company][:name])
          expect(json_response['registration_number']).to eq(valid_company_attributes[:company][:registration_number])
          expect(json_response['addresses'].size).to eq(2)

          json_response['addresses'].each do |address_data|
            expect(valid_addresses_attributes).to include(
              street: address_data['street'],
              city: address_data['city'],
              postal_code: address_data['postal_code'],
              country: address_data['country']
            )
          end
        end
      end

      context 'with invalid parameters' do
        let(:invalid_attributes) do
          {
            company: {
              name: '',
              registration_number: 'invalid',
              addresses_attributes: [
                attributes_for(:address, street: ''),
                attributes_for(:address, city: '')
              ]
            }
          }
        end

        it 'does not create a new Company and any of adresses' do
          expect {
            post '/api/v1/companies', params: invalid_attributes, headers: headers
          }.to change(Company, :count).by(0)
            .and change(Address, :count).by(0)
        end

        it 'returns status code 422' do
          post '/api/v1/companies', params: invalid_attributes, headers: headers
          expect(response).to have_http_status(:unprocessable_entity)
        end

        it 'returns validation errors' do
          post '/api/v1/companies', params: invalid_attributes, headers: headers
          json_response = JSON.parse(response.body)

          expect(json_response['title']).to eq('Validation Failed')
          expect(json_response['status']).to eq(422)
          expect(json_response['errors']).to include(
            'name' => [ "can't be blank" ],
            'registration_number' => [ 'is not a number' ],
            'addresses.street' => [ "can't be blank" ],
            'addresses.city' => [ "can't be blank" ]
          )
        end
      end
    end
  end
end
