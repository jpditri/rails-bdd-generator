# frozen_string_literal: true

FactoryBot.define do
  factory :book do
        title { Faker::Lorem.sentence }
    author { Faker::Lorem.sentence }
    isbn { Faker::Lorem.sentence }
    description { Faker::Lorem.sentence }
    price { rand(0.0..100.0).round(2) }
    stock_quantity { rand(1..100) }
    published_at { Faker::Date.between(from: 1.year.ago, to: Date.today) }
    category { Faker::Lorem.sentence }
    active { [true, false].sample }
        association :order_item
    association :review

    trait :expensive do
  price { 99999 }
end

trait :cheap do
  price { 1 }
end

trait :free do
  price { 0 }
end


trait :active do
  active { true }
end

trait :inactive do
  active { false }
end


trait :invalid do
  title { nil }
end

trait :for_testing do
  created_at { 1.day.ago }
  updated_at { 1.hour.ago }
end

  end
end
