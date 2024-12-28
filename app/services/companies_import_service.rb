require "csv"

ImportResult = Data.define(:imported_company_ids, :invalid_rows)

class CompaniesImportService
  attr_reader :file, :imported_company_ids, :invalid_rows

  def initialize(file)
    @file = file
    @imported_company_ids = Set.new
    @invalid_rows = []
  end

  def call
    each_csv_row do |row, index|
      company_attributes = row.slice(:name, :registration_number)
      address_attributes = row.slice(:street, :city, :postal_code, :country)

      Company.transaction do
        company = find_or_build_company(company_attributes)
        if add_or_update_address(company, address_attributes, index)
          save_company(company, index)
        end
      end
    end

    ImportResult.new(imported_company_ids:, invalid_rows:)
  end

  private

  def each_csv_row
    CSV.foreach(file.path, headers: true).with_index do |row, index|
      row_hash = row.to_h.with_indifferent_access
      yield(row_hash, index)
    end
  end

  def find_or_build_company(company_attributes)
    Company.find_or_initialize_by(registration_number: company_attributes[:registration_number]) do |company|
      company.name = company_attributes[:name]
    end
  end

  def add_or_update_address(company, address_attributes, index)
    return company.addresses.build(address_attributes) if company.new_record?

    address = find_or_build_address(company, address_attributes)

    return address.update!(address_attributes) if address.persisted?

    if address.valid?
      company.addresses << address
    else
      note_invalid_company_row(index, address.errors.full_messages.join(", "), address.errors)
      false
    end
  rescue ActiveRecord::RecordInvalid => e
    note_invalid_company_row(index, e.message, address.errors)
    false
  end

  def find_or_build_address(company, address_attributes)
    company.addresses.find_or_initialize_by(
      street: address_attributes["street"],
      city: address_attributes["city"],
      country: address_attributes["country"]
    ) do |address|
      address.postal_code = address_attributes["postal_code"]
    end
  end

  def save_company(company, index)
    if company.save
      @imported_company_ids << company.id
    else
      note_invalid_company_row(index, company.errors.full_messages.join(", "), company.errors)
    end
  end

  def note_invalid_company_row(index, detail, errors)
    @invalid_rows << {
      index:,
      detail:,
      errors:
    }
  end
end
