FactoryBot.define do
  factory :worker do
    sequence(:name) { |n| "Worker #{n}" }

    transient do
      qualifications { [] }
    end

    after(:create) do |worker, evaluator|
      worker.qualifications << evaluator.qualifications
    end
  end
end
