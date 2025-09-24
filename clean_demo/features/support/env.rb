require 'cucumber/rails'
require 'capybara/cucumber'

ActionController::Base.allow_rescue = false

DatabaseCleaner.strategy = :transaction
Cucumber::Rails::Database.javascript_strategy = :truncation
