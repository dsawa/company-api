json.imported_companies do
  json.array! @companies do |company|
    json.partial! "api/v1/companies/shared/company", company: company
    json.partial! "api/v1/companies/shared/addresses", addresses: company.addresses
  end
end
json.invalid_rows do
  json.array! @invalid_rows do |detail|
    json.index detail[:index]
    json.detail detail[:detail]
    json.errors detail[:errors]
  end
end
