json.data do
  json.array! @companies do |company|
    json.partial! "api/v1/companies/shared/company", company: company
    json.partial! "api/v1/companies/shared/addresses", addresses: company.addresses
  end
end
