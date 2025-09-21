# frozen_string_literal: true

FactoryBot.define do
  factory :user do
        email { Faker::Internet.email }
    first_name { Faker::Lorem.sentence }
    last_name { Faker::Lorem.sentence }
    role { Faker::Lorem.sentence }
        association :review

    trait :invalid do
  email { nil }
end

trait :for_testing do
  created_at { 1.day.ago }
  updated_at { 1.hour.ago }
end

  end
end
