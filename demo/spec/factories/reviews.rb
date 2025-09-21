# frozen_string_literal: true

FactoryBot.define do
  factory :review do
        rating { rand(1..100) }
    title { Faker::Lorem.sentence }
    content { Faker::Lorem.sentence }
    verified_purchase { [true, false].sample }
    

    trait :invalid do
  rating { nil }
end

trait :for_testing do
  created_at { 1.day.ago }
  updated_at { 1.hour.ago }
end

  end
end
