# Testing Best Practices

## Overview

The Rails BDD Generator now incorporates enterprise-grade testing patterns inspired by production applications. This document outlines the testing best practices and patterns that are automatically generated.

## Key Improvements

### 1. Comprehensive Factory System

Each model gets a factory with multiple traits for different testing scenarios:

```ruby
factory :user_wallet do
  # Default attributes
  gold_pieces { 100 }

  # Contextual traits
  trait :wealthy do
    gold_pieces { 5000 }
  end

  trait :broke do
    gold_pieces { 0 }
  end

  trait :for_testing do
    # Standardized test data
  end
end
```

### 2. Structured RSpec Tests

Tests are organized into clear sections:

- **Associations** - Validates relationships between models
- **Validations** - Tests data integrity rules
- **Callbacks** - Verifies lifecycle hooks
- **Scopes** - Tests query methods
- **Class Methods** - Tests model-level functionality
- **Instance Methods** - Tests object behavior
- **Business Logic** - Domain-specific rules

### 3. Feature Specs with Resilience

Feature specs handle multiple scenarios gracefully:

```ruby
describe 'OAuth login flow' do
  it 'allows user to sign in with GitHub' do
    if oauth_link_present?("github")
      # Test OAuth flow
    else
      # Gracefully handle non-OAuth environments
    end
  end
end
```

### 4. Test Helpers and Support

Generated test helpers include:

- **Authentication Helpers** - Sign in/out methods
- **API Helpers** - JSON parsing, auth headers
- **OAuth Helpers** - Mock OAuth providers
- **Shared Examples** - Reusable test patterns

### 5. Database Test Resilience

Tests handle:
- Transaction rollbacks
- Connection timeouts
- Concurrent access
- Data integrity violations

### 6. Performance Testing

Includes performance specs for:
- N+1 query detection
- Response time benchmarks
- Memory leak detection

## File Structure

```
spec/
├── models/           # Model specs with comprehensive coverage
├── controllers/      # Controller specs
├── features/        # Feature specs with Capybara
├── requests/        # API endpoint tests
├── factories/       # FactoryBot factories with traits
├── support/         # Helper modules and shared examples
├── integration/     # Integration tests
├── performance/     # Performance benchmarks
└── database_test_resilience_spec.rb
```

## Test Coverage Areas

### Model Testing
- Associations (belongs_to, has_many, etc.)
- Validations (presence, uniqueness, format)
- Callbacks (before_save, after_create)
- Scopes and class methods
- Business logic and calculations

### Feature Testing
- Complete user journeys
- Form submissions with validation
- Search and filtering
- Pagination
- Authorization checks
- OAuth authentication flows

### API Testing
- Endpoint availability
- Authentication/authorization
- Request/response formats
- Error handling
- Pagination metadata

## Configuration

The generator automatically configures:

- **RSpec** with Rails integration
- **FactoryBot** for test data
- **Faker** for realistic test data
- **DatabaseCleaner** for test isolation
- **Shoulda Matchers** for concise validations
- **Capybara** with Selenium for feature tests
- **SimpleCov** for code coverage
- **RSpec Retry** for flaky test handling

## Running Tests

After generation:

```bash
# Run all tests
bundle exec rspec

# Run specific test types
bundle exec rspec spec/models
bundle exec rspec spec/features
bundle exec rspec spec/requests

# Run with coverage
COVERAGE=true bundle exec rspec

# Run performance tests
bundle exec rspec spec/performance

# Run Cucumber features
bundle exec cucumber
```

## Best Practices Applied

1. **Test Isolation** - Each test runs in a clean database transaction
2. **Meaningful Assertions** - Tests check behavior, not implementation
3. **DRY Principles** - Shared examples and helpers reduce duplication
4. **Fast Feedback** - Unit tests run quickly, integration tests are selective
5. **Resilience** - Tests handle edge cases and environment variations
6. **Documentation** - Test names clearly describe expected behavior

## Continuous Integration

The generated test suite is CI-ready with:
- Headless browser testing
- Database setup/teardown
- Parallel test execution support
- Test result formatting

## Extending Tests

To add custom test patterns:

1. Add shared examples to `spec/support/shared_examples.rb`
2. Create custom matchers in `spec/support/matchers/`
3. Add helper methods to appropriate support files
4. Use factory traits for common test scenarios

## Troubleshooting

### Flaky Tests
- Tests automatically retry 3 times
- Check for timing issues in feature specs
- Ensure proper database cleanup

### Performance Issues
- Run performance specs separately
- Use `test-prof` for profiling
- Check for N+1 queries

### OAuth Testing
- OAuth is mocked by default
- Configure real OAuth for integration tests
- Check `spec/support/oauth_helpers.rb`