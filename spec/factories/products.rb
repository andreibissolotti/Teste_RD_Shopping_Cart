FactoryBot.define do
  factory :product do
    sequence(:name) { |n| "fake product #{n}" }
    price { Faker::Commerce.price(range: 10.0..1000.0) }
  end
end