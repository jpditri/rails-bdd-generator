# frozen_string_literal: true

# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'

# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?

require 'rspec/rails'
require 'factory_bot_rails'
require 'faker'
require 'shoulda/matchers'
require 'database_cleaner/active_record'
require 'capybara/rails'
require 'capybara/rspec'
require 'selenium-webdriver'

# Load support files
Dir[Rails.root.join('spec/support/**/*.rb')].sort.each { |f| require f }

# Checks for pending migrations and applies them before tests are run
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  puts e.to_s.strip
  exit 1
end

RSpec.configure do |config|
  # Include Factory Bot methods
  config.include FactoryBot::Syntax::Methods

  # Include test helpers
  config.include AuthenticationHelpers, type: :feature
  config.include ApiHelpers, type: :request
  config.include OAuthHelpers, type: :feature

  # Database cleaner configuration
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
    DatabaseCleaner.strategy = :transaction
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end

  config.around(:each, js: true) do |example|
    DatabaseCleaner.strategy = :truncation
    example.run
    DatabaseCleaner.strategy = :transaction
  end

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_path = "#{::Rails.root}/spec/fixtures"

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  config.use_transactional_fixtures = false

  config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!

  # Capybara configuration
  Capybara.javascript_driver = :selenium_chrome_headless
  Capybara.default_max_wait_time = 5
  Capybara.server = :puma, { Silent: true }

  # Retry flaky tests
  config.retry_mutant = 3
  config.verbose_retry = true
  config.display_try_failure_messages = true

  # Set up test data
  config.before(:each) do
    # Reset any test-specific configurations
    Rails.cache.clear
  end

  # Performance monitoring for slow tests
  config.profile_examples = 10 if ENV['PROFILE']

  # Seed for consistent random data
  config.order = :random
  Kernel.srand config.seed
end

# Shoulda Matchers configuration
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
