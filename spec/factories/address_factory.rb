FactoryBot.define do
  factory :address do
    street { Faker::Address.street_address }
    city { Faker::Address.city }
    postal_code { Faker::Address.zip_code }
    country { Faker::Address.country }

    association :company
  end
end
