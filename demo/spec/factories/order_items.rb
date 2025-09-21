# frozen_string_literal: true

FactoryBot.define do
  factory :order_item do
        quantity { rand(1..100) }
    unit_price { rand(0.0..100.0).round(2) }
    subtotal { rand(0.0..100.0).round(2) }
    

    trait :expensive do
  unit_price { 99999 }
end

trait :cheap do
  unit_price { 1 }
end

trait :free do
  unit_price { 0 }
end


trait :invalid do
  quantity { nil }
end

trait :for_testing do
  created_at { 1.day.ago }
  updated_at { 1.hour.ago }
end

  end
end
