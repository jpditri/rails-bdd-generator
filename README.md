# Rails BDD Generator

An agentic Ruby gem that generates complete Rails applications using Behavior-Driven Development (BDD) and Test-Driven Development (TDD) principles.

## Features

- 🤖 **AI-Powered Design**: Uses Claude AI to intelligently design your Rails application
- 🚀 **Agentic Generation**: Builds complete Rails 8 apps from simple descriptions
- 🧪 **Enterprise Testing**: Comprehensive test suite with factories, traits, and resilience patterns
- 🔐 **Rails 8 Authentication**: Uses Rails 8's built-in authentication (no Devise needed!)
- 📊 **Smart Database Design**: AI-designed entities, attributes, and relationships
- 🌐 **API First**: RESTful JSON API with authentication
- 🔍 **Search & Filter**: Built-in search, pagination, and filtering
- ✅ **Production Ready**: Validation, error handling, and security best practices
- 🎯 **Test Coverage**: Model specs, feature specs, request specs, and performance tests
- 🏭 **Smart Factories**: FactoryBot with contextual traits for realistic test data

## Installation

Add to your Gemfile:

```ruby
gem 'rails_bdd_generator'
```

Or install directly:

```bash
gem install rails_bdd_generator
```

## Setup

### API Key Configuration

To enable AI-powered generation, set your Anthropic API key:

```bash
export ANTHROPIC_API_KEY="your-api-key-here"
```

Without an API key, the generator will fall back to pattern-based extraction.

## Usage

### From Description (AI-Powered)

When you provide a description, the AI will:
1. Design the complete application architecture
2. Identify all necessary entities and attributes
3. Define relationships and business rules
4. Generate comprehensive BDD features
5. Create production-ready code

```ruby
require 'rails_bdd_generator'

# AI will design a complete card game platform with:
# - Cards, decks, collections, trades, tournaments
# - User authentication and authorization
# - API endpoints, background jobs
# - Complete test coverage
RailsBddGenerator.generate("Trading card collection manager with deck building and tournament support")
```

### From Specification

Provide detailed specifications:

```ruby
spec = {
  name: "CardVault",
  description: "Collectible card management platform",
  entities: [
    {
      name: "card",
      attributes: {
        name: :string,
        mana_cost: :integer,
        attack: :integer,
        defense: :integer,
        rarity: :string
      }
    },
    {
      name: "deck",
      attributes: {
        name: :string,
        format: :string
      }
    }
  ],
  relationships: [
    { from: "user", to: "deck", type: "has_many" },
    { from: "deck", to: "card", type: "has_and_belongs_to_many" }
  ]
}

RailsBddGenerator.generate(spec, output_path: "./card_vault")
```

### Command Line

```bash
# Generate from description
rails-bdd-generator -s "Card game collection tracker" -o ./my_app

# Generate from JSON specification
rails-bdd-generator -s cards_spec.json -o ./card_app

# Generate from YAML specification
rails-bdd-generator -s cards_spec.yml -o ./card_app
```

## Example: Collectible Cards App

Create a file `collectible_cards.json`:

```json
{
  "name": "CardVault",
  "description": "Trading card game collection manager",
  "entities": [
    {
      "name": "card",
      "attributes": {
        "name": "string",
        "mana_cost": "integer",
        "attack": "integer",
        "health": "integer",
        "rarity": "string",
        "set_code": "string",
        "card_text": "text"
      }
    },
    {
      "name": "deck",
      "attributes": {
        "name": "string",
        "format": "string",
        "description": "text"
      }
    },
    {
      "name": "collection_item",
      "attributes": {
        "card_id": "integer",
        "quantity": "integer",
        "foil": "boolean",
        "condition": "string"
      }
    }
  ],
  "relationships": [
    { "from": "user", "to": "collection_item", "type": "has_many" },
    { "from": "collection_item", "to": "card", "type": "belongs_to" },
    { "from": "user", "to": "deck", "type": "has_many" },
    { "from": "deck", "to": "card", "type": "has_and_belongs_to_many" }
  ]
}
```

Generate the app:

```bash
rails-bdd-generator -s collectible_cards.json -o ./card_vault
cd ./card_vault
bundle install
rails db:create db:migrate db:seed
rails server
```

## What Gets Generated

### Complete Rails Application
- Models with validations and associations
- RESTful controllers with authentication
- Views with forms and tables
- API endpoints with JSON serialization
- Database migrations
- Seed data

### Enterprise Test Suite
- **Model Specs**: Comprehensive testing with associations, validations, callbacks, and business logic
- **Feature Specs**: Resilient Capybara tests with OAuth support and graceful fallbacks
- **Request Specs**: API endpoint testing with authentication and pagination
- **Factory Bot**: Smart factories with contextual traits (wealthy, broke, pending, etc.)
- **Test Helpers**: Authentication, API, and OAuth helpers for DRY tests
- **Performance Tests**: N+1 detection, response time benchmarks, memory profiling
- **Database Resilience**: Transaction rollback handling and concurrent access tests
- **Shared Examples**: Reusable test patterns for common behaviors

### Authentication System
- Rails 8 built-in authentication
- Session-based authentication for web
- Token authentication for API
- User registration and login
- Password recovery
- Role-based access control

### API Layer
- Versioned REST API (v1)
- JSON serialization
- Pagination with Kaminari
- CORS configuration
- JWT authentication

## Generated Structure

```
my_app/
├── app/
│   ├── controllers/        # RESTful controllers
│   ├── models/             # ActiveRecord models
│   ├── views/              # ERB templates
│   ├── serializers/        # JSON serializers
│   └── services/           # Business logic
├── config/
│   ├── routes.rb           # RESTful routes
│   └── database.yml        # Database config
├── db/
│   ├── migrate/            # Migrations
│   └── seeds.rb            # Seed data
├── features/               # Cucumber tests
│   ├── step_definitions/
│   └── support/
├── spec/                   # RSpec tests
│   ├── models/
│   ├── controllers/
│   └── requests/
└── Gemfile                 # All dependencies
```

## Running Generated Apps

```bash
cd ./my_app
bundle install
rails db:create db:migrate db:seed
rails server
```

Run tests:
```bash
bundle exec rspec          # Run full test suite
bundle exec rspec spec/models     # Model tests only
bundle exec rspec spec/features   # Feature tests only
bundle exec rspec spec/requests   # API tests only
bundle exec cucumber       # BDD feature tests
COVERAGE=true bundle exec rspec   # With code coverage
```

See [TESTING_BEST_PRACTICES.md](TESTING_BEST_PRACTICES.md) for detailed testing documentation.

Default admin login:
- Email: admin@example.com
- Password: password123

## Requirements

- Ruby 3.3+
- Rails 8.0+
- PostgreSQL or SQLite
- Node.js (for assets)

## License

MIT License - see LICENSE file

## Contributing

1. Fork it
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit your changes (`git commit -am 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing`)
5. Create a Pull Request

## Support

- Issues: [GitHub Issues](https://github.com/jpditri/rails-bdd-generator/issues)
- Documentation: [Wiki](https://github.com/jpditri/rails-bdd-generator/wiki)

---

Generated with ❤️ by Rails BDD Generator