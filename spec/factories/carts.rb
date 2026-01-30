FactoryBot.define do
  factory :cart do
    total_price { 10.0 }
    status { 'active' }

    trait :abandoned do
      status { 'abandoned' }
    end
  end
end