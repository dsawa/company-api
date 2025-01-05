require 'rails_helper'

RSpec.describe 'Api::V1::Companies#import', type: :request do
  let(:headers) { { 'Accept': 'application/json' } }

  describe 'POST /api/v1/companies/import' do
    context 'when authenticated' do
      let(:user) { create(:user) }

      before do
        sign_in user
      end

      context 'with valid parameters' do
        let(:file) { fixture_file_upload(Rails.root.join('spec/fixtures/files/companies.csv'), 'text/csv') }

        it 'returns status code 200' do
          post '/api/v1/companies/import', params: { file: }, headers: headers

          expect(response).to have_http_status(:success)
        end

        it 'creates companies with addresses' do
          expect(Company.count).to eq(0)
          expect(Address.count).to eq(0)

          post '/api/v1/companies/import', params: { file: }, headers: headers

          expect(Company.count).to eq(2)
          expect(Address.count).to eq(3)

          company_1 = Company.find_by(registration_number: '123456789')
          company_2 = Company.find_by(registration_number: '987654321')

          expect(company_1.name).to eq('Example Co')
          expect(company_1.addresses.size).to eq(2)
          expect(company_1.addresses.map(&:city)).to match_array([ 'New York', 'Los Angeles' ])
          expect(company_1.addresses.map(&:postal_code)).to match_array([ '10001', '90001' ])
          expect(company_1.addresses.map(&:country)).to match_array([ 'USA', 'USA' ])
          expect(company_1.addresses.map(&:street)).to match_array([ '123 Main St', '456 Elm St' ])

          expect(company_2.name).to eq('Another Co')
          expect(company_2.addresses.size).to eq(1)
          expect(company_2.addresses.first.city).to eq('Chicago')
          expect(company_2.addresses.first.postal_code).to eq('60601')
          expect(company_2.addresses.first.country).to eq('USA')
          expect(company_2.addresses.first.street).to eq('789 Oak St')
        end

        it 'returns response with imported data' do
          expect(Company.count).to eq(0)
          expect(Address.count).to eq(0)

          post '/api/v1/companies/import', params: { file: }, headers: headers

          imported_companies = Company.all

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
        let(:expected_invalid_rows) do
          [
            { index: 1, detail: "Registration number is not a number", errors: { "registration_number" => [ "is not a number" ] } },
            { index: 2, detail: "Addresses city can't be blank", errors: { "addresses.city" => [ "can't be blank" ] } }
          ].map(&:with_indifferent_access)
        end

        it 'returns successful response' do
          post '/api/v1/companies/import', params: { file: invalid_csv_file }, headers: headers

          expect(response).to have_http_status(:success)
        end

        it 'creates only valid companies with addresses' do
          expect(Company.count).to eq(0)
          expect(Address.count).to eq(0)

          post '/api/v1/companies/import', params: { file: invalid_csv_file }, headers: headers

          expect(Company.count).to eq(1)
          expect(Address.count).to eq(1)

          company = Company.first
          address = company.addresses.first

          expect(company.name).to eq('Example Co')
          expect(company.registration_number).to eq(123456789)
          expect(address.street).to eq('123 Main St')
          expect(address.city).to eq('New York')
          expect(address.postal_code).to eq('10001')
          expect(address.country).to eq('USA')
        end

        it 'returns imported companies and validation messages' do
          post '/api/v1/companies/import', params: { file: invalid_csv_file }, headers: headers

          json_response = JSON.parse(response.body)
          expect(json_response['imported_companies'].size).to eq(1)
          expect(json_response['invalid_rows'].size).to eq(expected_invalid_rows.size)

          company = Company.first
          address = company.addresses.first

          imported_company_data = json_response['imported_companies'].first

          expect(imported_company_data['id']).to eq(company.id)
          expect(imported_company_data['name']).to eq(company.name)
          expect(imported_company_data['registration_number']).to eq(company.registration_number)
          expect(imported_company_data['addresses'].size).to eq(1)
          expect(imported_company_data['addresses'].first['street']).to eq(address.street)
          expect(imported_company_data['addresses'].first['city']).to eq(address.city)
          expect(imported_company_data['addresses'].first['postal_code']).to eq(address.postal_code.to_s)
          expect(imported_company_data['addresses'].first['country']).to eq(address.country)

          expect(json_response['invalid_rows']).to eq(expected_invalid_rows)
        end
      end
    end
  end
end
