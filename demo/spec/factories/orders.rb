# frozen_string_literal: true

FactoryBot.define do
  factory :order do
        order_number { Faker::Lorem.sentence }
    total_amount { rand(0.0..100.0).round(2) }
    status { Faker::Lorem.sentence }
    shipping_address { Faker::Lorem.sentence }
    payment_method { Faker::Lorem.sentence }
    notes { Faker::Lorem.sentence }
    shipped_at { Faker::Date.between(from: 1.year.ago, to: Date.today) }
        association :order_item

    trait :expensive do
  total_amount { 99999 }
end

trait :cheap do
  total_amount { 1 }
end

trait :free do
  total_amount { 0 }
end


trait :pending do
  status { 'pending' }
end

trait :approved do
  status { 'approved' }
end

trait :rejected do
  status { 'rejected' }
end

trait :completed do
  status { 'completed' }
end


trait :invalid do
  order_number { nil }
end

trait :for_testing do
  created_at { 1.day.ago }
  updated_at { 1.hour.ago }
end

  end
end
