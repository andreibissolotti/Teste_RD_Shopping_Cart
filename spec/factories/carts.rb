FactoryBot.define do
  factory :cart do
    total_price { 10.0 }
    status { 'active' }
    last_interaction_at { Time.current }
  end
end