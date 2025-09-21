# BookStore Demo Application

This demo showcases a Rails application generated with the Rails BDD Generator, featuring:

- 🎨 **Theme-aware UX** - Automatically styled based on the application domain (bookstore = literary theme)
- 🧪 **Comprehensive Testing** - Full test suite with factories, traits, and feature specs
- 🚀 **Production-Ready** - Complete with authentication, API, and admin features

## Features Demonstrated

### 1. Smart UX Enhancement
The generator automatically detects the application domain and applies appropriate theming:
- **Literary theme** for bookstores (warm browns, book-like aesthetics)
- **Commerce theme** for e-commerce sites
- **Gaming theme** for game-related apps
- **Medical theme** for healthcare applications

### 2. Responsive Components
- Card-based layouts
- Responsive tables with actions
- Search forms
- Pagination
- Alert messages
- Badge indicators

### 3. Testing Excellence
Every generated model includes:
```ruby
# Comprehensive factory with traits
factory :book do
  title { Faker::Book.title }
  price { rand(10.99..99.99) }

  trait :bestseller do
    rating { 5 }
    sales_count { rand(1000..10000) }
  end

  trait :out_of_stock do
    stock_quantity { 0 }
  end
end

# Full model spec coverage
RSpec.describe Book do
  describe 'associations'
  describe 'validations'
  describe 'callbacks'
  describe 'scopes'
  describe 'business logic'
end
```

### 4. Feature Specs with Resilience
```ruby
describe 'OAuth login flow' do
  it 'handles multiple authentication scenarios gracefully' do
    if oauth_configured?
      # Test OAuth flow
    else
      # Fall back to standard auth
    end
  end
end
```

## Generated Structure

```
demo/
├── app/
│   ├── assets/
│   │   ├── stylesheets/
│   │   │   └── application.scss    # Theme-aware styling
│   │   └── config/
│   │       └── manifest.js
│   ├── controllers/
│   │   ├── books_controller.rb
│   │   ├── orders_controller.rb
│   │   └── api/
│   │       └── v1/
│   │           └── books_controller.rb
│   ├── javascript/
│   │   └── application.js          # Interactive UX enhancements
│   ├── models/
│   │   ├── book.rb
│   │   ├── order.rb
│   │   └── review.rb
│   ├── views/
│   │   ├── layouts/
│   │   │   └── application.html.erb # Responsive layout
│   │   ├── shared/
│   │   │   ├── _dashboard.html.erb
│   │   │   ├── _search.html.erb
│   │   │   └── _stats.html.erb
│   │   └── books/
│   │       ├── index.html.erb      # Card-based listing
│   │       ├── show.html.erb       # Detailed view
│   │       └── _form.html.erb      # Smart forms
│   └── helpers/
│       └── application_helper.rb
├── spec/
│   ├── models/                     # Comprehensive model specs
│   ├── controllers/
│   ├── features/                   # Resilient feature specs
│   ├── requests/                   # API tests
│   ├── factories/                  # Smart factories with traits
│   ├── support/                    # Test helpers
│   └── performance/                # Performance tests
├── features/                        # Cucumber BDD tests
└── config/
    └── routes.rb
```

## UI Components

### Navigation Bar
- Gradient background matching theme
- Responsive menu
- User authentication links
- Active page highlighting

### Cards
- Clean, modern design
- Hover effects
- Organized content sections
- Action buttons

### Tables
- Responsive design
- Sortable columns
- Row hover effects
- Inline actions

### Forms
- Validation feedback
- Focus states
- Helpful text
- Error highlighting

### Buttons
- Primary, secondary, danger variants
- Size options (sm, md, lg)
- Hover animations
- Loading states

## Theme Colors

The bookstore demo uses a literary theme:

- **Primary**: #8B4513 (Saddle Brown)
- **Secondary**: #F5DEB3 (Wheat)
- **Accent**: #2F4F4F (Dark Slate Gray)
- **Success**: #228B22 (Forest Green)
- **Background**: #FAF8F5 (Off-white like pages)

## JavaScript Enhancements

- Smooth scrolling
- Form validation
- Auto-dismiss alerts
- Loading states
- Search debouncing
- Animations on scroll

## Running the Demo

```bash
cd demo
bundle install
rails db:create db:migrate db:seed
rails server
```

Visit http://localhost:3000 to see the application.

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test types
bundle exec rspec spec/models
bundle exec rspec spec/features
bundle exec rspec spec/requests

# Run with coverage
COVERAGE=true bundle exec rspec

# Run Cucumber features
bundle exec cucumber
```

## Key Files to Review

1. **UX Enhancement**: `lib/rails_bdd_generator/ux_enhancer.rb`
   - Theme detection logic
   - Component generation
   - Responsive styles

2. **Test Generation**: `lib/rails_bdd_generator/test_generator.rb`
   - Factory traits
   - Comprehensive specs
   - Helper modules

3. **Generated Views**: `app/views/books/index.html.erb`
   - Card layouts
   - Search integration
   - Pagination

4. **Model Specs**: `spec/models/book_spec.rb`
   - Association tests
   - Validation tests
   - Business logic tests

## Benefits

1. **Faster Development** - Complete app structure in minutes
2. **Best Practices** - Production patterns built-in
3. **Comprehensive Testing** - No untested code
4. **Beautiful UX** - Theme-aware, responsive design
5. **Maintainable** - Well-organized, documented code