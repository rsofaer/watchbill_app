FactoryBot.define do
  factory :watchstation do
    sequence(:name) { |n| "Watchstation #{n}" }
    watchset
    qualification
  end
end
