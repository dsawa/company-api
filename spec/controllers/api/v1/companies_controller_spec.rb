require 'rails_helper'

RSpec.describe Api::V1::CompaniesController, type: :controller do
  render_views

  context 'when user is authenticated' do
    let(:user) { create(:user) }

    before do
      sign_in user
    end

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

    describe 'POST #import' do
      let(:import_service) { instance_double(CompaniesImportService) }
      let(:import_result) { double('ImportResult') }

      before do
        allow(CompaniesImportService).to receive(:new).and_return(import_service)
      end

      context 'with valid CSV file' do
        let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/companies.csv'), 'text/csv') }
        let!(:imported_companies) { create_list(:company, 2, :with_addresses) }

        before do
          allow(import_result).to receive(:invalid_rows).and_return([])
          allow(import_result).to receive(:imported_company_ids).and_return(imported_companies.map(&:id))
          allow(import_service).to receive(:call).and_return(import_result)
        end

        it 'calls import service with file' do
          expect(CompaniesImportService).to receive(:new)
          expect(import_service).to receive(:call)

          post :import, params: { file: }, format: :json
        end

        it 'returns response with imported data' do
          post :import, params: { file: }, format: :json

          expect(response).to have_http_status(:success)
          json_response = JSON.parse(response.body)

          expect(json_response['imported_companies'].size).to eq(2)
          expect(json_response['invalid_rows']).to be_empty

          json_response['imported_companies'].each do |imported_company_data|
            imported_company = imported_companies.find { |company| company.id == imported_company_data['id'] }

            expect(imported_company_data['name']).to eq(imported_company.name)
            expect(imported_company_data['registration_number']).to eq(imported_company.registration_number)
            expect(imported_company_data['addresses'].sort_by { |h| h['postal_code'] }).to eq(
              imported_company.addresses.map { |address| address.attributes.slice('street', 'city', 'postal_code', 'country') }.sort_by { |h| h['postal_code'] }
            )
          end
        end
      end

      context 'with some invalid CSV rows' do
        let(:invalid_csv_file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/companies_with_invalid.csv'), 'text/csv') }
        let!(:imported_company) { create(:company, :with_addresses) }
        let(:invalid_rows) do
          [
            { index: 1, detail: "Registration number is not a number", errors: { "registration_number" => [ "is not a number" ] } },
            { index: 2, detail: "Addresses city can't be blank", errors: { "addresses.city" => [ "can't be blank" ] } }
        ].map(&:with_indifferent_access)
        end

        before do
          allow(import_result).to receive(:invalid_rows).and_return(invalid_rows)
          allow(import_result).to receive(:imported_company_ids).and_return([ imported_company.id ])
          allow(import_service).to receive(:call).and_return(import_result)
        end

        it 'returns imported companies and validation messages' do
          post :import, params: { file: invalid_csv_file }, format: :json

          json_response = JSON.parse(response.body)
          expect(json_response['imported_companies'].size).to eq(1)
          expect(json_response['invalid_rows'].size).to eq(2)

          imported_company_data = json_response['imported_companies'].first

          expect(imported_company_data['id']).to eq(imported_company.id)
          expect(imported_company_data['name']).to eq(imported_company.name)
          expect(imported_company_data['registration_number']).to eq(imported_company.registration_number)

          expect(json_response['invalid_rows']).to eq(invalid_rows)
        end
      end

      context 'with invalid file type' do
        let(:invalid_file_path) { Rails.root.join('spec/fixtures/files/empty.txt') }
        let(:invalid_file) { fixture_file_upload(invalid_file_path, 'text/plain') }

        it 'returns unprocessable_entity status' do
          post :import, params: { file: invalid_file }, format: :json

          expect(response).to have_http_status(:unprocessable_entity)

          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('Invalid File Type')
          expect(json_response['status']).to eq(422)
        end
      end

      context 'when file parameter is missing' do
        it 'returns bad_request status' do
          post :import, format: :json

          expect(response).to have_http_status(:bad_request)

          json_response = JSON.parse(response.body)
          expect(json_response['title']).to eq('File Not Found')
        end
      end
    end
  end

  context 'when user is not authenticated' do
    describe 'GET #index' do
      it 'returns unauthorized status' do
        get :index, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'GET #show' do
      it 'returns unauthorized status' do
        get :show, params: { id: 1 }, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'POST #create' do
      it 'returns unauthorized status' do
        post :create, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end

    describe 'POST #import' do
      it 'returns unauthorized status' do
        post :import, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
