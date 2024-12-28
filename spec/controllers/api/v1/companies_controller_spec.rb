require 'rails_helper'

RSpec.describe Api::V1::CompaniesController, type: :controller do
  render_views

  describe 'GET #index' do
    let!(:companies) { create_list(:company, 3) }

    it 'returns a successful response' do
      get :index, format: :json

      expect(response).to have_http_status(:success)
    end

    it 'returns all companies' do
      get :index, format: :json
      json_response = JSON.parse(response.body)
      expect(json_response['data'].size).to eq(3)
    end
  end

  describe 'GET #show' do
    let(:company) { create(:company) }

    context 'when company exists' do
      it 'returns a successful response' do
        get :show, params: { id: company.id }, format: :json
        expect(response).to have_http_status(:success)
      end

      it 'returns the correct company' do
        get :show, params: { id: company.id }, format: :json
        json_response = JSON.parse(response.body)
        expect(json_response['id']).to eq(company.id)
      end
    end

    context 'when company does not exist' do
      it 'returns not found status' do
        get :show, params: { id: 1 }, format: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end

  describe 'POST #create' do
    let(:valid_addresses_attributes) do
      [ FactoryBot.attributes_for(:address), FactoryBot.attributes_for(:address) ]
    end
    let(:valid_company_attributes) do
      { company: FactoryBot.attributes_for(:company).merge(addresses_attributes: valid_addresses_attributes) }
    end
    let(:invalid_company_attributes) do
      {
        company: {
          name: '',
          registration_number: 'ThisShouldBeNumber'
        }
      }
    end

    context 'with valid params' do
      it 'creates a new Company' do
        expect {
          post :create, params: valid_company_attributes, format: :json
        }.to change(Company, :count).by(1)
      end

      it 'creates associated address' do
        expect {
          post :create, params: valid_company_attributes, format: :json
        }.to change(Address, :count).by(2)
      end

      it 'returns created status' do
        post :create, params: valid_company_attributes, format: :json

        expect(response).to have_http_status(:created)
      end

      it 'returns the created company with correct attributes' do
        post :create, params: valid_company_attributes, format: :json

        json_response = JSON.parse(response.body)

        expect(json_response['name']).to eq(valid_company_attributes[:company][:name])
        expect(json_response['registration_number']).to eq(valid_company_attributes[:company][:registration_number])

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

    context 'with invalid Company params' do
      it 'does not create a new Company' do
        expect {
          post :create, params: invalid_company_attributes, format: :json
        }.not_to change(Company, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: invalid_company_attributes, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post :create, params: invalid_company_attributes, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['title']).to eq('Validation Failed')
        expect(json_response['status']).to eq(422)
        expect(json_response['detail']).to eq("Name can't be blank, Registration number is not a number")
        expect(json_response['errors']['name']).to eq([ "can't be blank" ])
        expect(json_response['errors']['registration_number']).to eq([ "is not a number" ])
      end
    end

    context 'with invalid Address params' do
      let(:invalid_addresses_attributes) do
        [ FactoryBot.attributes_for(:address, street: ''), FactoryBot.attributes_for(:address, city: '') ]
      end

      let(:valid_company_invalid_addresses_params) do
        valid_company_attributes.deep_merge(company: { addresses_attributes: invalid_addresses_attributes })
      end

      it 'does not create a new Address' do
        expect {
          post :create, params: valid_company_invalid_addresses_params, format: :json
        }.not_to change(Address, :count)
      end

      it 'returns unprocessable_entity status' do
        post :create, params: valid_company_invalid_addresses_params, format: :json

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'returns error messages' do
        post :create, params: valid_company_invalid_addresses_params, format: :json
        json_response = JSON.parse(response.body)

        expect(json_response['title']).to eq('Validation Failed')
        expect(json_response['status']).to eq(422)
        expect(json_response['detail']).to eq("Addresses street can't be blank, Addresses city can't be blank")
        expect(json_response['errors']['addresses.street']).to eq([ "can't be blank" ])
        expect(json_response['errors']['addresses.city']).to eq([ "can't be blank" ])
      end
    end
  end
end
