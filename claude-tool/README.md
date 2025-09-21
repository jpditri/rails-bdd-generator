# Rails BDD Generator - Claude Tool

This is the Claude MCP (Model Context Protocol) tool version of the Rails BDD Generator.

## Installation

### As a Claude Desktop Tool

1. Copy this directory to your Claude tools location
2. Add the tool manifest to your Claude configuration

### Environment Setup

```bash
# Required for AI-powered design
export ANTHROPIC_API_KEY="your-api-key-here"
```

## Usage in Claude

### Generate a Rails Application

```json
{
  "tool": "generate_rails_app",
  "params": {
    "description": "Trading card collection manager with deck building",
    "output_path": "./card_vault"
  }
}
```

### Design Application Architecture

```json
{
  "tool": "design_rails_app",
  "params": {
    "description": "E-commerce platform with inventory management"
  }
}
```

### Generate from Specification

```json
{
  "tool": "generate_rails_app",
  "params": {
    "specification": {
      "name": "BlogApp",
      "entities": [
        {
          "name": "post",
          "attributes": {
            "title": "string",
            "content": "text",
            "published": "boolean"
          }
        },
        {
          "name": "comment",
          "attributes": {
            "content": "text",
            "author": "string"
          }
        }
      ],
      "relationships": [
        {
          "from": "post",
          "to": "comment",
          "type": "has_many"
        }
      ]
    }
  }
}
```

## Command Line Testing

Test the tool from command line:

```bash
# Test generation
ruby rails_bdd_tool.rb generate "Blog with comments"

# Test design (requires API key)
ruby rails_bdd_tool.rb design "E-commerce platform"

# Run built-in tests
ruby rails_bdd_tool.rb test
```

## Tool Capabilities

### `generate_rails_app`
- Generates complete Rails 8 applications
- Creates models, controllers, views, and migrations
- Generates Cucumber BDD features
- Creates RSpec test suites
- Sets up API endpoints with authentication
- Can use AI for intelligent design or work from specifications

### `design_rails_app`
- Uses Claude AI to design application architecture
- Returns detailed specifications without generating code
- Identifies entities, relationships, and business rules
- Suggests features and API endpoints
- Requires ANTHROPIC_API_KEY

## Output Structure

### Success Response
```json
{
  "success": true,
  "app_path": "/path/to/generated/app",
  "entities_created": 5,
  "features_generated": 10,
  "next_steps": [
    "cd /path/to/app",
    "bundle install",
    "rails db:create db:migrate",
    "rails server"
  ]
}
```

### Error Response
```json
{
  "success": false,
  "error": "Error message",
  "hint": "Helpful suggestion"
}
```

## Features

- **AI-Powered Design**: Uses Claude to intelligently design Rails applications
- **Rails 8 Native**: Uses Rails 8's built-in authentication (no Devise)
- **Full BDD/TDD**: Generates Cucumber features and RSpec tests
- **API First**: Creates RESTful JSON APIs with JWT authentication
- **Production Ready**: Includes validations, error handling, and security
- **Fallback Mode**: Works without AI using pattern-based generation

## Requirements

- Ruby 3.3+
- Rails 8.0+
- ANTHROPIC_API_KEY (optional, for AI features)

## Integration with Claude Desktop

To use this as a Claude Desktop tool:

1. Place the tool in your Claude tools directory
2. Register the tool manifest
3. The tool will be available in Claude's tool menu

## Examples

### Trading Card Game
```
"Trading card collection manager with deck building and tournament support"
```

Generates:
- Card, Deck, Collection, Tournament models
- User authentication and authorization
- Trading system
- Tournament brackets
- API for mobile apps

### E-Commerce Platform
```
"E-commerce platform with inventory management and order fulfillment"
```

Generates:
- Product, Order, Inventory, Customer models
- Shopping cart functionality
- Payment processing structure
- Order tracking
- Admin dashboard

### Project Management
```
"Project management tool with tasks, teams, and time tracking"
```

Generates:
- Project, Task, Team, TimeEntry models
- Kanban board views
- Team collaboration features
- Time tracking and reporting
- REST API for integrations