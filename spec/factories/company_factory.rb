FactoryBot.define do
  factory :company do
    name { Faker::Company.name }
    sequence(:registration_number) { |n| n }

    trait :with_addresses do
      after(:create) do |company|
        create_list(:address, 2, company: company)
      end
    end
  end
end
