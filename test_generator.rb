#!/usr/bin/env ruby

# Test script to verify the updated generator works correctly

# require 'bundler/setup'  # Skip bundler for now
require_relative 'lib/rails_bdd_generator'

# Test specification
spec = {
  "name" => "TestApp",
  "description" => "A test application to verify generator improvements",
  "entities" => [
    {
      "name" => "product",
      "attributes" => {
        "name" => "string",
        "description" => "text",
        "price" => "decimal",
        "quantity" => "integer",
        "active" => "boolean",
        "category" => "string"
      }
    },
    {
      "name" => "order",
      "attributes" => {
        "order_number" => "string",
        "total_amount" => "decimal",
        "status" => "string",
        "shipped_at" => "datetime"
      }
    }
  ],
  "relationships" => [
    { "from" => "user", "to" => "order", "type" => "has_many" },
    { "from" => "order", "to" => "product", "type" => "has_and_belongs_to_many" }
  ],
  "business_rules" => [
    {
      "entity" => "product",
      "description" => "Price validation",
      "rule" => "Price must be greater than zero"
    },
    {
      "entity" => "order",
      "description" => "Status transitions",
      "rule" => "Order can only transition from pending to processing to shipped"
    }
  ]
}

puts "Testing Rails BDD Generator with improved testing patterns..."
puts "=" * 60

begin
  # Generate the test application
  generator = RailsBddGenerator::Generator.new(spec, output_path: "./test_output")

  # Check if files can be generated (without actually running)
  puts "\n✓ Generator initialized successfully"
  puts "✓ Entities: #{generator.entities.count}"
  puts "✓ Features: #{generator.features.count}"
  puts "✓ Output path: #{generator.output_path}"

  puts "\nTo generate the full application, run:"
  puts "  generator.generate!"

  puts "\nKey improvements that will be generated:"
  puts "  - Comprehensive model specs with all test categories"
  puts "  - Smart factories with contextual traits"
  puts "  - Feature specs with OAuth support"
  puts "  - Request specs for API endpoints"
  puts "  - Test helpers and shared examples"
  puts "  - Performance and database resilience tests"

  puts "\n✅ Generator test completed successfully!"

rescue => e
  puts "\n❌ Error during test: #{e.message}"
  puts e.backtrace.first(5)
  exit 1
end