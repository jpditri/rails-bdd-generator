#!/usr/bin/env ruby

# Generate demo bookstore app

require_relative 'lib/rails_bdd_generator/version'
require_relative 'lib/rails_bdd_generator/generator'

puts "Generating BookStore Demo App..."
puts "=" * 60

spec = JSON.parse(File.read('demo_spec.json'))
generator = RailsBddGenerator::Generator.new(spec, output_path: './demo')

begin
  generator.generate!
  puts "\n✅ Demo app generated successfully in ./demo"
rescue => e
  puts "\n❌ Error: #{e.message}"
  puts e.backtrace.first(10)
end