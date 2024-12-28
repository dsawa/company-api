json.partial! "api/v1/companies/shared/company", company: @company
json.partial! "api/v1/companies/shared/addresses", addresses: @company.addresses
