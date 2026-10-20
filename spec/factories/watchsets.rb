FactoryBot.define do
  factory :watchset do
    sequence(:name) { |n| "Watchset #{n}" }
  end
end
