require_relative 'lib/rails_bdd_generator/version'

Gem::Specification.new do |spec|
  spec.name          = "rails_bdd_generator"
  spec.version       = RailsBddGenerator::VERSION
  spec.authors       = ["BDD Generator Team"]
  spec.email         = ["support@rails-bdd-generator.com"]

  spec.summary       = %q{Generate complete Rails applications with BDD/TDD approach}
  spec.description   = %q{An agentic Ruby gem that generates complete Rails applications using BDD/TDD principles with Cucumber, RSpec, and full test coverage}
  spec.homepage      = "https://github.com/jpditri/rails-bdd-generator"
  spec.license       = "MIT"
  spec.required_ruby_version = Gem::Requirement.new(">= 2.7.0")

  spec.metadata["allowed_push_host"] = "https://rubygems.org"
  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/jpditri/rails-bdd-generator"
  spec.metadata["changelog_uri"] = "https://github.com/jpditri/rails-bdd-generator/blob/main/CHANGELOG.md"

  spec.files = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  end
  spec.bindir        = "bin"
  spec.executables   = ["rails-bdd-generator"]
  spec.require_paths = ["lib"]

  # Core Rails dependencies - required for generated apps
  spec.add_dependency "rails", "~> 7.1"
  spec.add_dependency "activesupport", ">= 7.0"
  spec.add_dependency "activerecord", ">= 7.0"
  spec.add_dependency "actionpack", ">= 7.0"
  spec.add_dependency "thor", "~> 1.0"

  # Database
  spec.add_dependency "pg", "~> 1.5"
  spec.add_dependency "sqlite3", "~> 1.6"

  # Authentication
  spec.add_dependency "devise", "~> 4.9"
  spec.add_dependency "devise-jwt", "~> 0.11"

  # Testing dependencies for generated apps
  spec.add_dependency "rspec-rails", "~> 6.0"
  spec.add_dependency "cucumber-rails", "~> 3.0"
  spec.add_dependency "database_cleaner-active_record", "~> 2.1"
  spec.add_dependency "factory_bot_rails", "~> 6.2"
  spec.add_dependency "faker", "~> 3.2"
  spec.add_dependency "shoulda-matchers", "~> 5.3"
  spec.add_dependency "capybara", "~> 3.39"
  spec.add_dependency "selenium-webdriver", "~> 4.15"

  # API
  spec.add_dependency "rack-cors", "~> 2.0"
  spec.add_dependency "active_model_serializers", "~> 0.10"
  spec.add_dependency "kaminari", "~> 1.2"

  # Development dependencies
  spec.add_development_dependency "bundler", "~> 2.0"
  spec.add_development_dependency "rake", "~> 13.0"
  spec.add_development_dependency "pry", "~> 0.14"
  spec.add_development_dependency "simplecov", "~> 0.22"
end