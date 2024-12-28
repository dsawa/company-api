require "rails_helper"

RSpec.describe CompaniesImportService do
  let(:service) { described_class.new(file) }

  describe "#call" do
    context "with valid CSV file" do
      let(:file) { fixture_file_upload("spec/fixtures/files/companies.csv") }

      it "properly imports companies with addresses" do
        expect {
          service.call
        }.to change(Company, :count).by(2).and change(Address, :count).by(3)

        example_co = Company.find_by(registration_number: 123456789)
        another_co = Company.find_by(registration_number: 987654321)

        expect(example_co.name).to eq("Example Co")
        expect(another_co.name).to eq("Another Co")

        expect(example_co.addresses.pluck(:street)).to match_array([ "123 Main St", "456 Elm St" ])
        expect(another_co.addresses.pluck(:street)).to match_array([ "789 Oak St" ])

        expect(example_co.addresses.pluck(:city)).to match_array([ "New York", "Los Angeles" ])
        expect(another_co.addresses.pluck(:city)).to match_array([ "Chicago" ])

        expect(example_co.addresses.pluck(:postal_code)).to match_array([ "10001", "90001" ])
        expect(another_co.addresses.pluck(:postal_code)).to match_array([ "60601" ])

        expect(example_co.addresses.pluck(:country)).to match_array([ "USA", "USA" ])
        expect(another_co.addresses.pluck(:country)).to match_array([ "USA" ])
      end

      it "returns result with import result data" do
        result = service.call

        expect(result.imported_company_ids.size).to eq(2)
        expect(result.invalid_rows).to be_empty
      end

      context "with existing companies" do
        let!(:existing_company) do
          Company.create!(name: "Example Co", registration_number: "123456789").tap do |company|
            company.addresses.create!(street: "Old St", city: "Old City", postal_code: "12345", country: "USA")
          end
        end

        it "updates existing company with adding new address" do
          expect {
            service.call
          }.to change { existing_company.addresses.count }.by(2)

          expect(Company.count).to eq(2)
        end
      end
    end

    context "with invalid CSV file" do
      let(:file) { fixture_file_upload("spec/fixtures/files/companies_with_invalid.csv") }

      it "imports valid data and does not break when invalid occurred" do
        result = service.call

        expect(result.imported_company_ids.size).to eq(1)

        imported_company = Company.find(result.imported_company_ids.first)

        expect(imported_company.name).to eq("Example Co")
        expect(imported_company.registration_number).to eq(123456789)

        imported_address = imported_company.addresses.first

        expect(imported_address.street).to eq("123 Main St")
        expect(imported_address.city).to eq("New York")
        expect(imported_address.postal_code).to eq("10001")
        expect(imported_address.country).to eq("USA")
      end

      it "returns result validation messages for invalid rows" do
        result = service.call
        expected_invalid_rows = [
          {
            index: 1,
            detail: "Registration number is not a number"
          },
          {
            index: 2,
            detail: "Addresses city can't be blank"
          }
        ]

        result.invalid_rows.each.with_index(0) do |invalid_row, index|
          expect(invalid_row[:index]).to eq(expected_invalid_rows[index][:index])
          expect(invalid_row[:detail]).to eq(expected_invalid_rows[index][:detail])
          expect(invalid_row[:errors]).to be_instance_of(ActiveModel::Errors)
        end
      end
    end
  end
end
