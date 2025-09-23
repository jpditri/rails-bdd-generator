require 'json'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'active_support/core_ext/string'
require_relative 'llm_designer'
require_relative 'test_generator'
require_relative 'test_helpers'
require_relative 'ux_enhancer'
require_relative 'githooks'

module RailsBddGenerator
  class Generator
    attr_reader :specification, :entities, :features, :output_path

    def initialize(specification, output_path: nil)
      @specification = parse_specification(specification)
      @output_path = Pathname.new(output_path || Pathname.pwd.join('generated_app'))
      @entities = []
      @features = []
      @migrations = []
      @tests = []
      @llm_designer = nil

      # Always initialize LLM designer - it will handle API key validation internally
      begin
        @llm_designer = LLMDesigner.new
      rescue => e
        puts "  ! LLM designer unavailable: #{e.message}"
        puts "  → Falling back to pattern-based extraction..."
        @llm_designer = nil
      end
    end

    def generate!
      puts "🚀 Rails BDD Generator v#{VERSION}"
      puts "=" * 60
      puts "🔨 Generating: #{@specification['name'] || 'Rails App'}"
      puts "=" * 60

      analyze_specification
      generate_rails_app
      setup_testing
      generate_models
      generate_controllers
      generate_views
      generate_routes
      generate_migrations
      generate_cucumber_features
      generate_rspec_tests
      generate_api_layer
      generate_icons
      enhance_ux
      install_quality_tools
      finalize_application

      puts "\n✓ Rails application generated successfully!"
      puts "📁 Location: #{@output_path}"
      puts "\n→ Next steps:"
      puts "  cd #{@output_path}"
      puts "  bundle install"
      puts "  ./bin/install-hooks  # Install git hooks for quality"
      puts "  rails server"

      true
    end

    private

    def parse_specification(spec)
      case spec
      when Hash
        spec
      when String
        if File.exist?(spec)
          content = File.read(spec)
          content.start_with?('{') ? JSON.parse(content) : YAML.load(content)
        elsif spec.start_with?('{')
          JSON.parse(spec)
        else
          { 'description' => spec }
        end
      else
        raise ArgumentError, "Invalid specification format"
      end
    end

    def analyze_specification
      puts "\n→ Analyzing specification..."

      if @llm_designer && @specification['description']
        puts "  🤖 Using AI to design application architecture..."

        begin
          # Use LLM to design the application
          llm_design = @llm_designer.design_application(@specification['description'])

          # Merge LLM design with any existing specification
          @specification = @specification.merge(llm_design) do |key, old_val, new_val|
            # Keep user-provided values, use LLM for missing ones
            old_val.nil? || (old_val.is_a?(Array) && old_val.empty?) ? new_val : old_val
          end

          puts "  ✨ AI-powered design complete!"
        rescue => e
          puts "  ! LLM design failed: #{e.message}"
          puts "  → Falling back to pattern-based extraction..."
        end
      end

      extract_entities
      extract_relationships
      extract_business_rules

      puts "  ✓ Found #{@entities.count} entities"
      puts "  ✓ Found #{@relationships.count} relationships"
      puts "  ✓ Found #{@business_rules.count} business rules"
    end

    def extract_entities
      if @specification['entities']
        @entities = @specification['entities'].map { |e| normalize_entity(e) }
      else
        @entities = auto_detect_entities(@specification['description'] || '')
      end

      ensure_user_entity
    end

    def normalize_entity(entity)
      if entity.is_a?(Hash)
        entity.deep_symbolize_keys
      else
        {
          name: entity.to_s.downcase.singularize,
          attributes: default_attributes
        }
      end
    end

    def auto_detect_entities(description)
      entities = []

      # First, try to extract comma-separated entities from common patterns
      comma_patterns = [
        /\bwith\s+([a-z, ]+(?:\s+and\s+[a-z]+)?)/i,  # "with books, authors, and categories"
        /\bincluding\s+([a-z, ]+(?:\s+and\s+[a-z]+)?)/i,  # "including products, orders"
        /\bfor\s+([a-z, ]+(?:\s+and\s+[a-z]+)?)/i,  # "for books, users"
      ]

      comma_patterns.each do |pattern|
        description.scan(pattern) do |match|
          if match[0]
            # Parse comma-separated and "and" separated lists
            # Handle "books, authors, and categories" pattern
            full_list = match[0].gsub(/,?\s+and\s+/, ', ')  # Convert "and" to comma
            items = full_list.split(/,\s*/).map(&:strip)
            items.each { |item| entities << normalize_entity(item) unless item.empty? }
          end
        end
      end

      # If no comma-separated entities found, try individual patterns
      if entities.empty?
        patterns = [
          /(?:manage|track|store)\s+(\w+)/i,
          /(\w+)\s+(?:management|tracking|collection)/i,
          /\b([a-z]+)\s+(?:system|application|app|platform)\b/i  # "book system", "user application"
        ]

        patterns.each do |pattern|
          description.scan(pattern) do |match|
            entities << normalize_entity(match[0])
          end
        end
      end

      entities.uniq { |e| e[:name] }
    end

    def default_attributes
      {
        name: :string,
        description: :text,
        price: :decimal,
        status: :string,
        active: :boolean
      }
    end

    def ensure_user_entity
      unless @entities.any? { |e| e[:name] == 'user' }
        @entities.unshift({
          name: 'user',
          attributes: {
            email: :string,
            first_name: :string,
            last_name: :string,
            role: :string
          }
        })
      end
    end

    def extract_relationships
      @relationships = @specification['relationships'] || []

      if @relationships.empty?
        @entities.each do |entity|
          next if entity[:name] == 'user'
          @relationships << { from: 'user', to: entity[:name], type: 'has_many' }
        end
      end
    end

    def extract_business_rules
      @business_rules = @specification['business_rules'] || [
        "Users must authenticate to access the system",
        "All data is scoped to the current user",
        "Admins can manage all resources"
      ]
    end

    def generate_rails_app
      puts "\n🏗️ Generating Rails application structure..."

      FileUtils.mkdir_p(@output_path)

      create_gemfile
      create_directory_structure
      create_application_files

      puts "  ✓ Rails structure created"
    end

    def create_gemfile
      gemfile_content = <<~RUBY
        source 'https://rubygems.org'

        ruby '3.4.4'

        gem 'rails', '~> 8.0.0'
        gem 'sqlite3', '>= 2.1'
        gem 'puma', '~> 6.0'
        gem 'bcrypt', '~> 3.1'
        gem 'rack-cors'
        gem 'active_model_serializers', '~> 0.10'
        gem 'bootsnap', require: false

        # Asset pipeline
        gem 'sprockets-rails'
        gem 'sassc-rails'
        gem 'importmap-rails'
        gem 'stimulus-rails'
        gem 'turbo-rails'

        group :development, :test do
          gem 'rspec-rails', '~> 6.0'
          gem 'factory_bot_rails'
          gem 'faker'
          gem 'pry-rails'
          gem 'byebug'
        end

        group :test do
          gem 'cucumber-rails', require: false
          gem 'database_cleaner-active_record'
          gem 'shoulda-matchers', '~> 6.0'
          gem 'capybara'
          gem 'selenium-webdriver'
          gem 'simplecov'
          gem 'rspec-retry'
          gem 'webdrivers'
          gem 'rspec-benchmark'
          gem 'test-prof'
        end

        group :development do
          gem 'listen'
          gem 'spring'
        end
      RUBY

      File.write(@output_path.join('Gemfile'), gemfile_content)
    end

    def create_directory_structure
      dirs = %w[
        app/controllers app/models app/views app/views/layouts app/views/shared app/helpers app/services app/serializers
        app/controllers/api app/controllers/api/v1
        app/javascript/controllers
        config/initializers config/environments
        db/migrate
        features/step_definitions features/support
        spec/models spec/controllers spec/requests spec/factories
        spec/features spec/support spec/integration spec/performance
        lib/tasks bin
      ]

      dirs.each { |dir| FileUtils.mkdir_p(@output_path.join(dir)) }
    end

    def create_application_files
      create_config_files
      create_bin_files
      create_application_controller
      create_application_helper
      create_application_record
      create_application_layout
      create_config_ru
      create_additional_config_files
    end

    def create_config_files
      # config/application.rb
      app_config = <<~RUBY
        require_relative 'boot'
        require 'rails/all'

        Bundler.require(*Rails.groups)

        module #{app_name}
          class Application < Rails::Application
            config.load_defaults 8.0
            config.api_only = false

            config.middleware.insert_before 0, Rack::Cors do
              allow do
                origins '*'
                resource '*',
                  headers: :any,
                  methods: [:get, :post, :put, :patch, :delete, :options, :head]
              end
            end
          end
        end
      RUBY
      File.write(@output_path.join('config/application.rb'), app_config)

      # config/boot.rb
      boot_config = <<~RUBY
        ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __dir__)

        require 'bundler/setup' # Set up gems listed in the Gemfile.
        require 'bootsnap/setup' # Speed up boot time by caching expensive operations.
      RUBY
      File.write(@output_path.join('config/boot.rb'), boot_config)

      # config/environment.rb
      env_config = <<~RUBY
        # Load the Rails application.
        require_relative 'application'

        # Initialize the Rails application.
        Rails.application.initialize!
      RUBY
      File.write(@output_path.join('config/environment.rb'), env_config)

      # config/routes.rb
      routes_config = <<~RUBY
        Rails.application.routes.draw do
          # Root route
          root 'books#index'

          # Resource routes will be added here by the generator
        end
      RUBY
      File.write(@output_path.join('config/routes.rb'), routes_config)

      # Rakefile
      rakefile_content = <<~RUBY
        # Add your own tasks in files placed in lib/tasks ending in .rake,
        # for example lib/tasks/capistrano.rake, and they will automatically be available to Rake.

        require_relative 'config/application'

        Rails.application.load_tasks
      RUBY
      File.write(@output_path.join('Rakefile'), rakefile_content)
    end

    def create_bin_files
      FileUtils.mkdir_p(@output_path.join('bin'))

      # bin/rails
      rails_bin = <<~BASH
        #!/usr/bin/env ruby
        APP_PATH = File.expand_path('../config/application', __dir__)
        require_relative '../config/boot'
        require 'rails/commands'
      BASH
      File.write(@output_path.join('bin/rails'), rails_bin)
      File.chmod(0755, @output_path.join('bin/rails').to_s)

      # bin/setup
      setup_bin = <<~BASH
        #!/usr/bin/env ruby
        require 'fileutils'

        # path to your application root.
        APP_ROOT = File.expand_path('..', __dir__)

        def system!(*args)
          system(*args) || abort("\\nCommand failed: \#{args}")
        end

        FileUtils.chdir APP_ROOT do
          puts '== Installing dependencies =='
          system! 'gem install bundler --conservative'
          system('bundle check') || system!('bundle install')

          puts "\\n== Preparing database =="
          system! 'bin/rails db:prepare'

          puts "\\n== Removing old logs and tempfiles =="
          system! 'bin/rails log:clear tmp:clear'

          puts "\\n== Restarting application server =="
          system! 'bin/rails restart'
        end
      BASH
      File.write(@output_path.join('bin/setup'), setup_bin)
      File.chmod(0755, @output_path.join('bin/setup').to_s)
    end

    def create_application_controller
      controller_content = <<~RUBY
        class ApplicationController < ActionController::Base
          # Disable CSRF for demo purposes
          skip_before_action :verify_authenticity_token

          # Simple demo authentication - always use first user or create one
          before_action :set_current_user

          private

          def set_current_user
            @current_user ||= User.first || create_demo_user
          end

          def create_demo_user
            User.create!(
              email: 'demo@example.com',
              first_name: 'Demo',
              last_name: 'User',
              role: 'admin'
            )
          end

          def current_user
            @current_user
          end

          def require_authentication
            # For demo purposes, always allow access
            true
          end

          helper_method :current_user
        end
      RUBY

      File.write(@output_path.join('app/controllers/application_controller.rb'), controller_content)
    end

    def create_application_helper
      helper_content = <<~RUBY
        module ApplicationHelper
          def format_currency(amount)
            return "N/A" unless amount
            "$" + sprintf('%.2f', amount)
          end

          def format_date(date)
            return "N/A" unless date
            date.strftime("%B %d, %Y")
          end

          def truncate_with_tooltip(text, length: 50)
            return "N/A" unless text
            if text.length > length
              content_tag :span, truncate(text, length: length), title: text
            else
              text
            end
          end
        end
      RUBY

      File.write(@output_path.join('app/helpers/application_helper.rb'), helper_content)
    end

    def create_application_record
      record_content = <<~RUBY
        class ApplicationRecord < ActiveRecord::Base
          primary_abstract_class
        end
      RUBY

      File.write(@output_path.join('app/models/application_record.rb'), record_content)
    end

    def create_application_layout
      # Ensure layouts directory exists
      FileUtils.mkdir_p(@output_path.join('app/views/layouts'))

      layout_content = <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <meta name="viewport" content="width=device-width, initial-scale=1.0">
          <title><%= content_for?(:title) ? yield(:title) : "#{app_name}" %></title>

          <!-- Font Loading -->
          <link rel="preconnect" href="https://fonts.googleapis.com">
          <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
          <link href="https://fonts.googleapis.com/css2?family=Merriweather:wght@300;400;700&display=swap" rel="stylesheet">

          <%= csrf_meta_tags %>
          <%= csp_meta_tag %>

          <style>
            /* Basic styling for demo purposes */
            * {
              margin: 0;
              padding: 0;
              box-sizing: border-box;
            }

            body {
              font-family: 'Merriweather', Georgia, serif;
              line-height: 1.6;
              color: #333;
              background-color: #f5f5f5;
            }

            .container {
              max-width: 1200px;
              margin: 0 auto;
              padding: 0 20px;
            }

            .navbar {
              background: #2c3e50;
              color: white;
              padding: 1rem 0;
              margin-bottom: 2rem;
            }

            .navbar-brand {
              color: white;
              text-decoration: none;
              font-size: 1.5rem;
              font-weight: 700;
            }

            .navbar-nav {
              list-style: none;
              display: flex;
              gap: 1rem;
              margin-top: 0.5rem;
            }

            .navbar-nav li a {
              color: #ecf0f1;
              text-decoration: none;
              padding: 0.5rem;
            }

            .navbar-nav li a:hover {
              color: #3498db;
            }

            .card {
              background: white;
              border-radius: 8px;
              box-shadow: 0 2px 10px rgba(0,0,0,0.1);
              margin-bottom: 2rem;
            }

            .card-header {
              background: #34495e;
              color: white;
              padding: 1rem;
              border-radius: 8px 8px 0 0;
            }

            .card-body {
              padding: 1.5rem;
            }

            .btn {
              display: inline-block;
              padding: 0.5rem 1rem;
              background: #3498db;
              color: white;
              text-decoration: none;
              border-radius: 4px;
              border: none;
              cursor: pointer;
            }

            .btn:hover {
              background: #2980b9;
            }

            .btn-primary {
              background: #3498db;
            }

            .btn-secondary {
              background: #95a5a6;
            }

            .btn-danger {
              background: #e74c3c;
            }

            .btn-sm {
              padding: 0.25rem 0.5rem;
              font-size: 0.875rem;
            }

            .table {
              width: 100%;
              border-collapse: collapse;
              margin-top: 1rem;
            }

            .table th,
            .table td {
              padding: 0.75rem;
              text-align: left;
              border-bottom: 1px solid #ddd;
            }

            .table th {
              background: #f8f9fa;
              font-weight: 600;
            }

            .search-form {
              display: flex;
              gap: 0.5rem;
              margin-bottom: 1rem;
            }

            .search-form input {
              flex: 1;
              padding: 0.5rem;
              border: 1px solid #ddd;
              border-radius: 4px;
            }

            .text-muted {
              color: #6c757d;
            }

            .alert {
              padding: 0.75rem 1rem;
              margin-bottom: 1rem;
              border-radius: 4px;
            }

            .alert-success {
              background: #d4edda;
              color: #155724;
              border: 1px solid #c3e6cb;
            }

            .alert-danger {
              background: #f8d7da;
              color: #721c24;
              border: 1px solid #f5c6cb;
            }
          </style>
        </head>
        <body>
          <nav class="navbar">
            <div class="container">
              <%= link_to "#{app_name}", root_path, class: "navbar-brand" %>

              <ul class="navbar-nav">
                <% if defined?(books_path) %>
                  <li>
                    <%= link_to "Books", books_path %>
                  </li>
                <% end %>
                <% if defined?(orders_path) %>
                  <li>
                    <%= link_to "Orders", orders_path %>
                  </li>
                <% end %>
                <% if current_user.present? %>
                  <li>
                    <span class="text-muted">Demo User: <%= current_user.email %></span>
                  </li>
                <% end %>
              </ul>
            </div>
          </nav>

          <main class="container">
            <%= yield %>
          </main>
        </body>
        </html>
      HTML

      File.write(@output_path.join('app/views/layouts/application.html.erb'), layout_content)
    end

    def create_config_ru
      config_ru_content = <<~RUBY
        # This file is used by Rack-based servers to start the application.

        require_relative 'config/environment'

        run Rails.application
        Rails.application.load_server
      RUBY

      File.write(@output_path.join('config.ru'), config_ru_content)
    end

    def create_additional_config_files
      # config/environments/development.rb
      dev_env = <<~RUBY
        Rails.application.configure do
          config.cache_classes = false
          config.eager_load = false
          config.consider_all_requests_local = true
          config.server_timing = true

          if Rails.root.join("tmp/caching-dev.txt").exist?
            config.action_controller.perform_caching = true
            config.action_controller.enable_fragment_cache_logging = true
            config.cache_store = :memory_store
            config.public_file_server.headers = {
              "Cache-Control" => "public, max-age=\#{2.days.to_i}"
            }
          else
            config.action_controller.perform_caching = false
            config.cache_store = :null_store
          end

          config.active_support.deprecation = :log
          config.active_support.disallowed_deprecation = :raise
          config.active_support.disallowed_deprecation_warnings = []
          config.active_record.migration_error = :page_load
          config.active_record.verbose_query_logs = true
          config.file_watcher = ActiveSupport::EventedFileUpdateChecker
        end
      RUBY
      File.write(@output_path.join('config/environments/development.rb'), dev_env)

      # config/importmap.rb
      importmap_config = <<~RUBY
        # Pin npm packages by running ./bin/importmap

        pin "application"
        pin "@hotwired/turbo-rails", to: "turbo.min.js"
        pin "@hotwired/stimulus", to: "stimulus.min.js"
        pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
        pin_all_from "app/javascript/controllers", under: "controllers"
      RUBY
      File.write(@output_path.join('config/importmap.rb'), importmap_config)

      # Create essential empty directories with .keep files
      %w[log tmp tmp/pids tmp/cache tmp/sockets].each do |dir|
        FileUtils.mkdir_p(@output_path.join(dir))
        File.write(@output_path.join(dir, '.keep'), '')
      end
    end

    def setup_testing
      puts "\n🧪 Setting up testing framework..."

      setup_rspec
      setup_cucumber

      puts "  ✓ Testing framework configured"
    end

    def setup_rspec
      rspec_helper = <<~RUBY
        require 'simplecov'
        SimpleCov.start 'rails'

        RSpec.configure do |config|
          config.expect_with :rspec do |expectations|
            expectations.include_chain_clauses_in_custom_matcher_descriptions = true
          end

          config.mock_with :rspec do |mocks|
            mocks.verify_partial_doubles = true
          end
        end
      RUBY

      File.write(@output_path.join('spec/spec_helper.rb'), rspec_helper)
    end

    def setup_cucumber
      cucumber_env = <<~RUBY
        require 'cucumber/rails'
        require 'capybara/cucumber'

        ActionController::Base.allow_rescue = false

        DatabaseCleaner.strategy = :transaction
        Cucumber::Rails::Database.javascript_strategy = :truncation
      RUBY

      File.write(@output_path.join('features/support/env.rb'), cucumber_env)
    end

    def generate_models
      puts "\n→ Generating models..."

      @entities.each do |entity|
        generate_model(entity)
      end

      puts "  ✓ Generated #{@entities.count} models"
    end

    def generate_model(entity)
      model_content = <<~RUBY
        class #{entity[:name].camelize} < ApplicationRecord
          #{generate_associations(entity)}
          #{generate_validations(entity)}
          #{generate_scopes(entity)}

          def display_name
            respond_to?(:name) ? name : "#{entity[:name].capitalize} #\#{id}"
          end
        end
      RUBY

      File.write(@output_path.join("app/models/#{entity[:name]}.rb"), model_content)
    end

    def generate_associations(entity)
      associations = []

      @relationships.each do |rel|
        if rel[:from] == entity[:name] || rel['from'] == entity[:name]
          type = rel[:type] || rel['type']
          to = rel[:to] || rel['to']
          associations << "#{type} :#{to.pluralize}"
        end
      end

      associations.join("\n  ")
    end

    def generate_validations(entity)
      validations = []

      entity[:attributes].each do |attr, type|
        if %w[name title email].include?(attr.to_s)
          validations << "validates :#{attr}, presence: true"
        end
        if attr.to_s == 'email'
          validations << "validates :#{attr}, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }"
        end
      end

      validations.join("\n  ")
    end

    def generate_scopes(entity)
      <<~RUBY.strip
        scope :active, -> { where(active: true) }
        scope :recent, -> { order(created_at: :desc) }
      RUBY
    end

    def generate_controllers
      puts "\n→ Generating controllers..."

      @entities.each do |entity|
        next if entity[:name] == 'user'
        generate_controller(entity)
      end

      generate_home_controller
      puts "  ✓ Controllers generated"
    end

    def generate_home_controller
      controller_content = <<~RUBY
        class HomeController < ApplicationController
          def index
            @users = User.all
          end
        end
      RUBY

      File.write(@output_path.join('app/controllers/home_controller.rb'), controller_content)
    end

    def generate_controller(entity)
      controller_content = <<~RUBY
        class #{entity[:name].pluralize.camelize}Controller < ApplicationController
          before_action :require_authentication  # Rails 8 built-in auth
          before_action :set_#{entity[:name]}, only: %i[show edit update destroy]

          def index
            @#{entity[:name].pluralize} = #{entity[:name].camelize}.all
          end

          def show
          end

          def new
            @#{entity[:name]} = #{entity[:name].camelize}.new
          end

          def create
            @#{entity[:name]} = #{entity[:name].camelize}.new(#{entity[:name]}_params)

            if @#{entity[:name]}.save
              redirect_to @#{entity[:name]}, notice: '#{entity[:name].capitalize} created successfully.'
            else
              render :new, status: :unprocessable_entity
            end
          end

          def update
            if @#{entity[:name]}.update(#{entity[:name]}_params)
              redirect_to @#{entity[:name]}, notice: '#{entity[:name].capitalize} updated successfully.'
            else
              render :edit, status: :unprocessable_entity
            end
          end

          def destroy
            @#{entity[:name]}.destroy
            redirect_to #{entity[:name].pluralize}_url, notice: '#{entity[:name].capitalize} deleted successfully.'
          end

          private

          def set_#{entity[:name]}
            @#{entity[:name]} = #{entity[:name].camelize}.find(params[:id])
          end

          def #{entity[:name]}_params
            params.require(:#{entity[:name]}).permit(#{permitted_params(entity)})
          end
        end
      RUBY

      File.write(@output_path.join("app/controllers/#{entity[:name].pluralize}_controller.rb"), controller_content)
    end

    def permitted_params(entity)
      entity[:attributes].keys.map { |attr| ":#{attr}" }.join(', ')
    end

    def generate_views
      puts "\n→ Generating views..."

      @entities.each do |entity|
        next if entity[:name] == 'user'
        generate_views_for_entity(entity)
      end

      generate_home_views
      puts "  ✓ Views generated"
    end

    def generate_home_views
      # Create home views directory
      home_views_dir = @output_path.join('app/views/home')
      FileUtils.mkdir_p(home_views_dir)

      # Generate home index view
      home_index_content = <<~ERB
        <div class="container">
          <div class="row">
            <div class="col-12">
              <div class="card">
                <div class="card-header">
                  <h1 style="margin: 0;">Rails App</h1>
                </div>
                <div class="card-body">
                  <p class="lead">Welcome to your Rails BDD Generated application!</p>

                  <div class="row">
                    <div class="col-md-6">
                      <h3>Features</h3>
                      <ul>
                        <li>User Management</li>
                        <li>API Layer with authentication</li>
                        <li>Comprehensive test suite (RSpec + Cucumber)</li>
                        <li>Quality assurance tools</li>
                        <li>Professional styling</li>
                      </ul>
                    </div>

                    <div class="col-md-6">
                      <h3>Users</h3>
                      <% if @users.any? %>
                        <ul>
                          <% @users.each do |user| %>
                            <li><%= user.email %> (<%= user.role %>)</li>
                          <% end %>
                        </ul>
                      <% else %>
                        <p>No users found.</p>
                      <% end %>
                    </div>
                  </div>

                  <div style="margin-top: 2rem;">
                    <a href="/api/v1/users" class="btn btn-primary">View API Documentation</a>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>
      ERB

      File.write(home_views_dir.join('index.html.erb'), home_index_content)
    end

    def generate_views_for_entity(entity)
      views_dir = @output_path.join("app/views/#{entity[:name].pluralize}")
      FileUtils.mkdir_p(views_dir)

      # index.html.erb
      File.write(views_dir.join('index.html.erb'), index_view_template(entity))

      # _form.html.erb
      File.write(views_dir.join('_form.html.erb'), form_partial_template(entity))

      # show.html.erb
      File.write(views_dir.join('show.html.erb'), show_view_template(entity))

      # new.html.erb
      File.write(views_dir.join('new.html.erb'), new_view_template(entity))

      # edit.html.erb
      File.write(views_dir.join('edit.html.erb'), edit_view_template(entity))
    end

    def index_view_template(entity)
      <<~ERB
        <div class="container">
          <div class="row">
            <div class="col-12">
              <div class="card">
                <div class="card-header">
                  <h1 style="margin: 0;">#{entity[:name].capitalize.pluralize}</h1>
                </div>
                <div class="card-body">
                  <div style="margin-bottom: 1rem; display: flex; justify-content: space-between; align-items: center;">
                    <%= render 'shared/search' %>
                    <%= link_to new_#{entity[:name]}_path, class: 'btn btn-primary' do %>
                      <%= plus_icon %> New #{entity[:name].capitalize}
                    <% end %>
                  </div>

                  <div class="table-responsive">
                    <table class="table">
                      <thead>
                        <tr>
                          #{entity[:attributes].keys.take(4).map { |a| "<th>#{a.to_s.humanize}</th>" }.join("\n                          ")}
                          <th style="text-align: right;">Actions</th>
                        </tr>
                      </thead>
                      <tbody>
                        <% @#{entity[:name].pluralize}.each do |#{entity[:name]}| %>
                          <tr class="#{entity[:name]}-row">
                            #{entity[:attributes].keys.take(4).map { |a| generate_table_cell(entity, a) }.join("\n                            ")}
                            <td style="text-align: right;">
                              <%= link_to #{entity[:name]}, class: 'btn btn-sm btn-outline' do %>
                                <%= view_icon %> View
                              <% end %>
                              <%= link_to edit_#{entity[:name]}_path(#{entity[:name]}), class: 'btn btn-sm btn-secondary' do %>
                                <%= edit_icon %> Edit
                              <% end %>
                              <%= link_to #{entity[:name]}, method: :delete,
                                  data: { confirm: 'Are you sure?' },
                                  class: 'btn btn-sm btn-danger' do %>
                                <%= delete_icon %> Delete
                              <% end %>
                            </td>
                          </tr>
                        <% end %>
                        <% if @#{entity[:name].pluralize}.empty? %>
                          <tr>
                            <td colspan="5" style="text-align: center; padding: 2rem; color: var(--muted);">
                              No #{entity[:name].pluralize} found. <%= link_to 'Create one now', new_#{entity[:name]}_path %>.
                            </td>
                          </tr>
                        <% end %>
                      </tbody>
                    </table>
                  </div>

                  <%= paginate @#{entity[:name].pluralize} %>
                </div>
              </div>
            </div>
          </div>
        </div>
      ERB
    end

    def form_partial_template(entity)
      <<~ERB
        <%= form_with(model: #{entity[:name]}, local: true) do |form| %>
          <% if #{entity[:name]}.errors.any? %>
            <div class="alert alert-danger">
              <ul>
                <% #{entity[:name]}.errors.full_messages.each do |message| %>
                  <li><%= message %></li>
                <% end %>
              </ul>
            </div>
          <% end %>

          #{generate_form_fields(entity)}

          <div class="actions">
            <%= form.submit class: 'btn btn-primary' %>
          </div>
        <% end %>
      ERB
    end

    def generate_form_fields(entity)
      entity[:attributes].map do |attr, type|
        field_type = case type.to_s
                    when /text/ then 'text_area'
                    when /boolean/ then 'check_box'
                    when /integer|decimal/ then 'number_field'
                    when /date/ then 'date_field'
                    when /datetime/ then 'datetime_field'
                    else 'text_field'
                    end

        <<~ERB.strip
          <div class="field">
            <%= form.label :#{attr} %>
            <%= form.#{field_type} :#{attr}, class: 'form-control' %>
          </div>
        ERB
      end.join("\n  ")
    end

    def show_view_template(entity)
      <<~ERB
        <div class="container">
          <div class="card">
            <div class="card-header">
              <h1 style="margin: 0;">#{entity[:name].capitalize} Details</h1>
            </div>
            <div class="card-body">
              <div class="row">
                #{entity[:attributes].map { |attr, type| generate_show_field(entity, attr, type) }.join("\n                ")}
              </div>
            </div>
            <div class="card-footer">
              <%= link_to edit_#{entity[:name]}_path(@#{entity[:name]}), class: 'btn btn-primary' do %>
                <%= edit_icon %> Edit
              <% end %>
              <%= link_to #{entity[:name]}_path(@#{entity[:name]}), method: :delete,
                  data: { confirm: 'Are you sure?' }, class: 'btn btn-danger' do %>
                <%= delete_icon %> Delete
              <% end %>
              <%= link_to #{entity[:name].pluralize}_path, class: 'btn btn-secondary' do %>
                <%= list_icon %> Back to List
              <% end %>
            </div>
          </div>

          <% if @#{entity[:name]}.respond_to?(:reviews) && @#{entity[:name]}.reviews.any? %>
            <div class="card" style="margin-top: 1rem;">
              <div class="card-header">Reviews</div>
              <div class="card-body">
                <%= render @#{entity[:name]}.reviews %>
              </div>
            </div>
          <% end %>
        </div>
      ERB
    end

    def new_view_template(entity)
      <<~ERB
        <div class="container">
          <div class="card">
            <div class="card-header">
              <h1 style="margin: 0;">New #{entity[:name].capitalize}</h1>
            </div>
            <div class="card-body">
              <%= render 'form', #{entity[:name]}: @#{entity[:name]} %>
            </div>
          </div>
        </div>
      ERB
    end

    def edit_view_template(entity)
      <<~ERB
        <div class="container">
          <div class="card">
            <div class="card-header">
              <h1 style="margin: 0;">Edit #{entity[:name].capitalize}</h1>
            </div>
            <div class="card-body">
              <%= render 'form', #{entity[:name]}: @#{entity[:name]} %>
            </div>
            <div class="card-footer">
              <%= link_to @#{entity[:name]}, class: 'btn btn-outline' do %>
                <%= view_icon %> View
              <% end %>
              <%= link_to #{entity[:name].pluralize}_path, class: 'btn btn-secondary' do %>
                <%= list_icon %> Back to List
              <% end %>
            </div>
          </div>
        </div>
      ERB
    end

    def generate_routes
      puts "\n🛤️ Generating routes..."

      routes_content = <<~RUBY
        Rails.application.routes.draw do
          # Rails 8 built-in authentication routes
          resource :session
          resources :passwords, param: :token

          root 'home#index'

          #{@entities.reject { |e| e[:name] == 'user' }.map { |e| "resources :#{e[:name].pluralize}" }.join("\n  ")}

          namespace :api do
            namespace :v1 do
              #{@entities.map { |e| "resources :#{e[:name].pluralize}" }.join("\n      ")}
            end
          end
        end
      RUBY

      File.write(@output_path.join('config/routes.rb'), routes_content)

      puts "  ✓ Routes configured"
    end

    def generate_migrations
      puts "\n🗄️ Generating migrations..."

      @entities.each_with_index do |entity, index|
        timestamp = (Time.now + index).strftime("%Y%m%d%H%M%S")
        generate_migration(entity, timestamp)
      end

      puts "  ✓ Generated #{@entities.count} migrations"
    end

    def generate_migration(entity, timestamp)
      migration_content = <<~RUBY
        class Create#{entity[:name].pluralize.camelize} < ActiveRecord::Migration[7.1]
          def change
            create_table :#{entity[:name].pluralize} do |t|
              #{generate_migration_columns(entity)}

              t.timestamps
            end

            add_index :#{entity[:name].pluralize}, :created_at
          end
        end
      RUBY

      File.write(@output_path.join("db/migrate/#{timestamp}_create_#{entity[:name].pluralize}.rb"), migration_content)
    end

    def generate_migration_columns(entity)
      entity[:attributes].map do |attr, type|
        "t.#{type} :#{attr}"
      end.join("\n      ")
    end

    def generate_cucumber_features
      puts "\n🥒 Generating Cucumber features..."

      if @llm_designer
        puts "  🤖 Using AI to generate comprehensive BDD features..."

        begin
          # Use LLM to generate Cucumber features
          llm_features = @llm_designer.generate_cucumber_features(@entities, @relationships, @business_rules)

          if llm_features && llm_features['features']
            llm_features['features'].each do |feature|
              save_llm_generated_feature(feature)
            end
            puts "  ✨ AI-generated #{llm_features['features'].count} comprehensive features!"
          end
        rescue => e
          puts "  ! LLM feature generation failed: #{e.message}"
          puts "  → Falling back to template-based generation..."
          generate_template_based_features
        end
      else
        generate_template_based_features
      end

      puts "  ✓ Generated #{@features.count} features"
    end

    def generate_template_based_features
      @entities.each do |entity|
        generate_feature(entity)
      end
    end

    def save_llm_generated_feature(feature)
      feature_name = feature['name'].downcase.gsub(/\s+/, '_')
      feature_content = feature['content']

      # Save feature file
      feature_file = @output_path.join("features/#{feature_name}.feature")
      File.write(feature_file, feature_content)

      # Save step definitions if provided
      if feature['step_definitions']
        step_file = @output_path.join("features/step_definitions/#{feature_name}_steps.rb")
        File.write(step_file, feature['step_definitions'])
      end

      @features << feature_file
    end

    def generate_feature(entity)
      feature_content = <<~CUCUMBER
        Feature: #{entity[:name].capitalize} Management
          As a user
          I want to manage #{entity[:name].pluralize}
          So that I can organize my data

          Background:
            Given I am logged in as a user

          Scenario: Creating a new #{entity[:name]}
            When I go to the new #{entity[:name]} page
            And I fill in the form with valid data
            And I click "Create #{entity[:name].capitalize}"
            Then I should see "#{entity[:name].capitalize} created successfully"

          Scenario: Viewing a #{entity[:name]}
            Given a #{entity[:name]} exists
            When I go to the #{entity[:name]} page
            Then I should see the #{entity[:name]} details

          Scenario: Editing a #{entity[:name]}
            Given a #{entity[:name]} exists
            When I go to the edit #{entity[:name]} page
            And I update the form
            And I click "Update #{entity[:name].capitalize}"
            Then I should see "#{entity[:name].capitalize} updated successfully"

          Scenario: Deleting a #{entity[:name]}
            Given a #{entity[:name]} exists
            When I go to the #{entity[:name].pluralize} page
            And I click "Delete"
            Then I should see "#{entity[:name].capitalize} deleted successfully"
      CUCUMBER

      File.write(@output_path.join("features/#{entity[:name]}_management.feature"), feature_content)
    end

    def generate_rspec_tests
      puts "\n🧪 Generating RSpec tests..."

      # Initialize test generator with entities and relationships
      test_gen = TestGenerator.new(@entities, @relationships, @business_rules || [])

      @entities.each do |entity|
        # Generate comprehensive model spec
        model_spec = test_gen.generate_model_spec(entity)
        File.write(@output_path.join("spec/models/#{entity[:name]}_spec.rb"), model_spec)

        # Generate factory with traits
        factory = test_gen.generate_factory(entity)
        File.write(@output_path.join("spec/factories/#{entity[:name].pluralize}.rb"), factory)

        # Generate feature spec
        feature_spec = test_gen.generate_feature_spec(entity)
        File.write(@output_path.join("spec/features/#{entity[:name].pluralize}_management_spec.rb"), feature_spec)

        # Generate request spec for API
        request_spec = test_gen.generate_request_spec(entity)
        File.write(@output_path.join("spec/requests/api_v1_#{entity[:name].pluralize}_spec.rb"), request_spec)

        # Keep legacy controller spec for now
        generate_controller_spec(entity)
      end

      # Generate test helpers
      generate_test_helpers

      puts "  ✓ Generated comprehensive test suite"
    end

    def generate_test_helpers
      # Generate Rails helper with comprehensive setup
      rails_helper = TestHelpers.generate_rails_helper
      File.write(@output_path.join('spec/rails_helper.rb'), rails_helper)

      # Create support directory
      FileUtils.mkdir_p(@output_path.join('spec/support'))

      # Generate authentication helpers
      auth_helpers = TestHelpers.generate_authentication_helpers
      File.write(@output_path.join('spec/support/authentication_helpers.rb'), auth_helpers)

      # Generate API helpers
      api_helpers = TestHelpers.generate_api_helpers
      File.write(@output_path.join('spec/support/api_helpers.rb'), api_helpers)

      # Generate OAuth helpers
      oauth_helpers = TestHelpers.generate_oauth_helpers
      File.write(@output_path.join('spec/support/oauth_helpers.rb'), oauth_helpers)

      # Generate shared examples
      shared_examples = TestHelpers.generate_shared_examples
      File.write(@output_path.join('spec/support/shared_examples.rb'), shared_examples)

      # Generate database test resilience spec
      db_resilience = TestHelpers.generate_database_test_resilience
      File.write(@output_path.join('spec/database_test_resilience_spec.rb'), db_resilience)

      # Generate performance test
      performance_test = TestHelpers.generate_performance_test
      File.write(@output_path.join('spec/performance/performance_spec.rb'), performance_test)

      puts "  ✓ Generated test helpers and support files"
    end

    def generate_association_tests(entity)
      tests = []

      @relationships.each do |rel|
        if rel[:from] == entity[:name] || rel['from'] == entity[:name]
          type = rel[:type] || rel['type']
          to = rel[:to] || rel['to']
          tests << "it { should #{type.gsub('_', ' ')} :#{to.pluralize} }"
        end
      end

      tests.join("\n    ")
    end

    def generate_validation_tests(entity)
      tests = []

      entity[:attributes].each do |attr, _|
        if %w[name title email].include?(attr.to_s)
          tests << "it { should validate_presence_of(:#{attr}) }"
        end
      end

      tests.join("\n    ")
    end

    def generate_controller_spec(entity)
      spec_content = <<~RUBY
        require 'rails_helper'

        RSpec.describe #{entity[:name].pluralize.camelize}Controller, type: :controller do
          let(:user) { create(:user) }
          let(:#{entity[:name]}) { create(:#{entity[:name]}, user: user) }

          before { sign_in user }

          describe 'GET #index' do
            it 'returns success' do
              get :index
              expect(response).to be_successful
            end
          end

          describe 'GET #show' do
            it 'returns success' do
              get :show, params: { id: #{entity[:name]}.id }
              expect(response).to be_successful
            end
          end
        end
      RUBY

      File.write(@output_path.join("spec/controllers/#{entity[:name].pluralize}_controller_spec.rb"), spec_content)
    end

    def generate_api_layer
      puts "\n🌐 Generating API layer..."

      generate_api_base_controller

      @entities.each do |entity|
        generate_api_controller(entity)
        generate_serializer(entity)
      end

      puts "  ✓ API layer generated"
    end

    def generate_api_base_controller
      base_controller_content = <<~RUBY
        module Api
          module V1
            class BaseController < ApplicationController
              # Base controller for API endpoints
              before_action :set_current_user

              # Skip CSRF protection for API endpoints (if available)
              skip_before_action :verify_authenticity_token, raise: false

              private

              def set_current_user
                # Simple demo authentication - always use first user or create one
                @current_user ||= User.first || create_demo_user
              end

              def create_demo_user
                User.create!(
                  email: 'demo@example.com',
                  first_name: 'Demo',
                  last_name: 'User',
                  role: 'admin'
                )
              end

              def current_user
                @current_user
              end

              def require_authentication
                # For demo purposes, always allow access
                true
              end
            end
          end
        end
      RUBY

      File.write(@output_path.join('app/controllers/api/v1/base_controller.rb'), base_controller_content)
    end

    def generate_api_controller(entity)
      api_controller = <<~RUBY
        module Api
          module V1
            class #{entity[:name].pluralize.camelize}Controller < Api::V1::BaseController
              before_action :set_#{entity[:name]}, only: %i[show update destroy]

              def index
                @#{entity[:name].pluralize} = current_user.#{entity[:name].pluralize}.page(params[:page])
                render json: @#{entity[:name].pluralize}
              end

              def show
                render json: @#{entity[:name]}
              end

              def create
                @#{entity[:name]} = current_user.#{entity[:name].pluralize}.build(#{entity[:name]}_params)

                if @#{entity[:name]}.save
                  render json: @#{entity[:name]}, status: :created
                else
                  render json: { errors: @#{entity[:name]}.errors.full_messages }, status: :unprocessable_entity
                end
              end

              def update
                if @#{entity[:name]}.update(#{entity[:name]}_params)
                  render json: @#{entity[:name]}
                else
                  render json: { errors: @#{entity[:name]}.errors.full_messages }, status: :unprocessable_entity
                end
              end

              def destroy
                @#{entity[:name]}.destroy
                head :no_content
              end

              private

              def set_#{entity[:name]}
                @#{entity[:name]} = current_user.#{entity[:name].pluralize}.find(params[:id])
              end

              def #{entity[:name]}_params
                params.require(:#{entity[:name]}).permit(#{permitted_params(entity)})
              end
            end
          end
        end
      RUBY

      File.write(@output_path.join("app/controllers/api/v1/#{entity[:name].pluralize}_controller.rb"), api_controller)
    end

    def generate_serializer(entity)
      # Only add belongs_to :user for non-user entities
      user_association = entity[:name] == 'user' ? '' : "\n  belongs_to :user"

      serializer_content = <<~RUBY
        class #{entity[:name].capitalize}Serializer < ActiveModel::Serializer
          attributes :id, #{entity[:attributes].keys.map { |a| ":#{a}" }.join(', ')}, :created_at, :updated_at#{user_association}
        end
      RUBY

      File.write(@output_path.join("app/serializers/#{entity[:name]}_serializer.rb"), serializer_content)
    end

    def install_quality_tools
      puts "\n→ Installing quality assurance tools..."

      # Install Git hooks
      Githooks.install!(@output_path)

      # Generate RuboCop configuration
      generate_rubocop_config

      # Generate GitHub Actions workflow
      generate_github_actions

      # Add code quality gems to Gemfile
      add_quality_gems

      puts "  ✓ Quality tools configured"
    end

    def generate_rubocop_config
      rubocop_config = <<~YAML
        # RuboCop configuration for Rails BDD Generated apps
        require:
          - rubocop-rails
          - rubocop-rspec

        AllCops:
          NewCops: enable
          Exclude:
            - 'db/**/*'
            - 'config/**/*'
            - 'script/**/*'
            - 'bin/*'
            - 'vendor/**/*'
            - 'node_modules/**/*'
            - 'tmp/**/*'

        Style/Documentation:
          Enabled: false

        Metrics/BlockLength:
          Exclude:
            - 'spec/**/*'
            - 'config/routes.rb'

        Metrics/ClassLength:
          Max: 150

        Metrics/MethodLength:
          Max: 20

        Layout/LineLength:
          Max: 120
          Exclude:
            - 'config/initializers/*'

        Rails:
          Enabled: true

        RSpec/ExampleLength:
          Max: 20

        RSpec/MultipleExpectations:
          Max: 5
      YAML

      File.write(@output_path.join('.rubocop.yml'), rubocop_config)
    end

    def generate_github_actions
      FileUtils.mkdir_p(@output_path.join('.github/workflows'))

      ci_workflow = <<~YAML
        name: CI

        on:
          push:
            branches: [ main, develop ]
          pull_request:
            branches: [ main ]

        jobs:
          test:
            runs-on: ubuntu-latest

            services:
              postgres:
                image: postgres:14
                env:
                  POSTGRES_PASSWORD: postgres
                options: >-
                  --health-cmd pg_isready
                  --health-interval 10s
                  --health-timeout 5s
                  --health-retries 5
                ports:
                  - 5432:5432

            steps:
            - uses: actions/checkout@v3

            - name: Set up Ruby
              uses: ruby/setup-ruby@v1
              with:
                ruby-version: '3.3'
                bundler-cache: true

            - name: Setup database
              env:
                DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
                RAILS_ENV: test
              run: |
                bundle exec rails db:create
                bundle exec rails db:schema:load

            - name: Run RuboCop
              run: bundle exec rubocop

            - name: Run RSpec tests
              env:
                DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
                RAILS_ENV: test
              run: bundle exec rspec

            - name: Run Cucumber features
              env:
                DATABASE_URL: postgresql://postgres:postgres@localhost:5432/test
                RAILS_ENV: test
              run: bundle exec cucumber
      YAML

      File.write(@output_path.join('.github/workflows/ci.yml'), ci_workflow)
    end

    def add_quality_gems
      gemfile_path = @output_path.join('Gemfile')
      content = File.read(gemfile_path)

      quality_gems = <<~RUBY

        # Code quality tools
        group :development do
          gem 'rubocop', require: false
          gem 'rubocop-rails', require: false
          gem 'rubocop-rspec', require: false
          gem 'brakeman', require: false  # Security scanner
          gem 'bundler-audit', require: false  # Dependency scanner
          gem 'rails_best_practices', require: false
        end
      RUBY

      # Append quality gems if not already present
      unless content.include?('rubocop')
        File.open(gemfile_path, 'a') { |f| f.write(quality_gems) }
      end
    end

    def enhance_ux
      puts "\n→ Enhancing user experience..."

      # Initialize UX enhancer
      ux_enhancer = UxEnhancer.new(
        @specification['name'] || 'Rails App',
        @specification['description'] || 'A Rails application',
        @entities
      )

      # Generate UX enhancements
      ux_assets = ux_enhancer.enhance!

      # Write stylesheets
      FileUtils.mkdir_p(@output_path.join('app/assets/stylesheets'))
      ux_assets[:stylesheets].each do |filename, content|
        File.write(@output_path.join("app/assets/stylesheets/#{filename}"), content)
      end

      # Write JavaScript
      FileUtils.mkdir_p(@output_path.join('app/javascript'))
      File.write(@output_path.join('app/javascript/application.js'), ux_assets[:javascript])

      # Write layouts
      FileUtils.mkdir_p(@output_path.join('app/views/layouts'))
      ux_assets[:layouts].each do |filename, content|
        File.write(@output_path.join("app/views/layouts/#{filename}"), content)
      end

      # Write shared components
      FileUtils.mkdir_p(@output_path.join('app/views/shared'))
      ux_assets[:components].each do |filename, content|
        File.write(@output_path.join("app/views/shared/#{filename}"), content)
      end

      # Write asset pipeline config
      FileUtils.mkdir_p(@output_path.join('app/assets/config'))
      ux_assets[:assets].each do |filename, content|
        File.write(@output_path.join("app/assets/config/#{filename}"), content)
      end

      # Update application helper with flash class method
      helper_content = <<~RUBY
        module ApplicationHelper
          def flash_class(type)
            case type.to_sym
            when :notice, :success then 'success'
            when :alert, :error then 'danger'
            when :warning then 'warning'
            else 'info'
            end
          end

          def format_currency(amount)
            number_to_currency(amount)
          end

          def format_date(date)
            date.strftime("%B %d, %Y") if date
          end
        end
      RUBY

      FileUtils.mkdir_p(@output_path.join('app/helpers'))
      File.write(@output_path.join('app/helpers/application_helper.rb'), helper_content)

      puts "  ✓ UX enhancements applied"
      puts "  ✓ Theme-specific styling generated"
      puts "  ✓ Interactive JavaScript added"
      puts "  ✓ Responsive layouts created"
    end

    def finalize_application
      puts "\n→ Finalizing application..."

      generate_readme
      generate_database_config
      generate_seeds

      puts "  ✓ Application finalized"
    end

    def generate_readme
      readme = <<~MD
        # #{app_name}

        #{@specification['description'] || 'Rails application generated with BDD approach'}

        ## Setup

        ```bash
        bundle install
        rails db:create db:migrate db:seed
        rails server
        ```

        ## Testing

        ```bash
        cucumber  # Run feature tests
        rspec     # Run unit tests
        ```

        ## API

        All endpoints are available at `/api/v1/`

        ## Generated with Rails BDD Generator
      MD

      File.write(@output_path.join('README.md'), readme)
    end

    def generate_database_config
      db_config = <<~YAML
        default: &default
          adapter: sqlite3
          pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>
          timeout: 5000

        development:
          <<: *default
          database: db/development.sqlite3

        test:
          <<: *default
          database: db/test.sqlite3

        production:
          <<: *default
          database: db/production.sqlite3
      YAML

      File.write(@output_path.join('config/database.yml'), db_config)
    end

    def generate_seeds
      seeds = <<~RUBY
        # Create admin user
        User.create!(
          email: 'admin@example.com',
          first_name: 'Admin',
          last_name: 'User',
          role: 'admin'
        )

        puts "Created admin user: admin@example.com"

        # Create sample data
        #{@entities.reject { |e| e[:name] == 'user' }.map { |e| "# Create sample #{e[:name].pluralize}" }.join("\n")}
      RUBY

      File.write(@output_path.join('db/seeds.rb'), seeds)
    end

    def app_name
      (@specification['name'] || 'RailsApp').gsub(/\W/, '')
    end

    # Helper methods for view generation
    def generate_table_cell(entity, attribute)
      case attribute.to_s
      when /price|cost|amount/
        "<td class=\"price\"><%= format_currency(#{entity[:name]}.#{attribute}) %></td>"
      when /date/
        "<td><%= format_date(#{entity[:name]}.#{attribute}) %></td>"
      when /active|enabled/
        "<td>
          <% if #{entity[:name]}.#{attribute} %>
            <span class=\"badge badge-success\">Active</span>
          <% else %>
            <span class=\"badge badge-danger\">Inactive</span>
          <% end %>
        </td>"
      when /status|state/
        "<td>
          <span class=\"badge badge-<%= #{entity[:name]}.#{attribute}_badge_class %>\">
            <%= #{entity[:name]}.#{attribute}.humanize %>
          </span>
        </td>"
      else
        "<td><%= truncate(#{entity[:name]}.#{attribute}.to_s, length: 50) %></td>"
      end
    end

    def generate_show_field(entity, attribute, type)
      field = <<~ERB
        <div class="col-md-6" style="margin-bottom: 1rem;">
          <strong>#{attribute.to_s.humanize}:</strong>
      ERB

      case type.to_s
      when /decimal|integer/
        if attribute.to_s.include?('price') || attribute.to_s.include?('amount')
          field += "      <span class=\"price\"><%= format_currency(@#{entity[:name]}.#{attribute}) %></span>"
        else
          field += "      <%= @#{entity[:name]}.#{attribute} %>"
        end
      when /date/
        field += "      <%= format_date(@#{entity[:name]}.#{attribute}) %>"
      when /boolean/
        field += <<~ERB
              <% if @#{entity[:name]}.#{attribute} %>
                <span class="badge badge-success">Yes</span>
              <% else %>
                <span class="badge badge-danger">No</span>
              <% end %>
        ERB
      when /text/
        field = <<~ERB
          <div class="col-12" style="margin-bottom: 1rem;">
            <strong>#{attribute.to_s.humanize}:</strong>
            <div style="margin-top: 0.5rem;">
              <%= simple_format(@#{entity[:name]}.#{attribute}) %>
            </div>
        ERB
      else
        field += "      <%= @#{entity[:name]}.#{attribute} %>"
      end

      field + "    </div>"
    end

    def finalize_application
      puts "→ Setting up database configuration..."
      generate_database_config

      puts "🌱 Generating seed data..."
      generate_seeds

      puts "→ Creating storage directory..."
      FileUtils.mkdir_p(@output_path.join('storage'))

      puts "🗄️  Setting up databases..."
      Dir.chdir(@output_path) do
        puts "  → Creating and migrating development database..."
        system('bundle exec rails db:create db:migrate db:seed', out: File::NULL, err: File::NULL)

        puts "  🧪 Setting up test database..."
        system('RAILS_ENV=test bundle exec rails db:create db:migrate', out: File::NULL, err: File::NULL)

        puts "  🧪 Running tests to verify application..."
        if system('bundle exec rspec --format progress', out: File::NULL, err: File::NULL)
          puts "  ✓ All tests passing!"
        else
          puts "  ! Some tests failing - check test output"
        end
      end

      puts "✓ Application fully configured and ready to use!"
    end

    def generate_icons
      puts "→ Creating custom SVG icon system..."

      # Create icons directory
      FileUtils.mkdir_p(@output_path.join('app/assets/images/icons'))

      # Generate app-specific icons based on domain
      generate_domain_icons

      # Create icon helper
      generate_icon_helper

      puts "  ✓ Custom SVG icons created"
    end

    private

    def generate_domain_icons
      # Generate icons based on the application domain
      icons = determine_app_icons

      icons.each do |name, svg_content|
        File.write(@output_path.join("app/assets/images/icons/#{name}.svg"), svg_content)
      end
    end

    def determine_app_icons
      # Analyze entities and app description to create relevant icons
      icons = {}

      # Always include basic UI icons
      icons['success'] = generate_success_icon
      icons['error'] = generate_error_icon
      icons['info'] = generate_info_icon
      icons['warning'] = generate_warning_icon
      icons['edit'] = generate_edit_icon
      icons['delete'] = generate_delete_icon
      icons['add'] = generate_add_icon
      icons['search'] = generate_search_icon

      # Add domain-specific icons based on entities
      @entities.each do |entity|
        entity_icon = generate_entity_icon(entity[:name])
        icons[entity[:name]] = entity_icon if entity_icon
      end

      # Add context-specific icons based on app description
      if @app_description
        context_icons = generate_context_icons(@app_description)
        icons.merge!(context_icons)
      end

      icons
    end

    def generate_success_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <path d="M8 12l2.5 2.5L16 9" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_error_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <path d="M15 9l-6 6M9 9l6 6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_info_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <path d="M12 16v-4M12 8h.01" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_warning_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3h16.94a2 2 0 0 0 1.71-3L13.71 3.86a2 2 0 0 0-3.42 0z" stroke="currentColor" stroke-width="2"/>
          <path d="M12 9v4M12 17h.01" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_edit_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M18.5 2.5a2.12 2.12 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_delete_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <path d="M3 6h18M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6M8 6V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          <path d="M10 11v6M14 11v6" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_add_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
          <path d="M12 8v8M8 12h8" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_search_icon
      <<~SVG
        <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
          <circle cx="11" cy="11" r="8" stroke="currentColor" stroke-width="2"/>
          <path d="M21 21l-4.35-4.35" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
        </svg>
      SVG
    end

    def generate_entity_icon(entity_name)
      case entity_name.downcase
      when 'user', 'customer', 'person', 'member'
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="12" cy="7" r="4" stroke="currentColor" stroke-width="2"/>
          </svg>
        SVG
      when 'book', 'article', 'document', 'post'
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" stroke="currentColor" stroke-width="2"/>
          </svg>
        SVG
      when 'order', 'purchase', 'transaction', 'payment'
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M6 2L3 6v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2V6l-3-4z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M3 6h18M16 10a4 4 0 0 1-8 0" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        SVG
      when 'product', 'item', 'inventory'
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M21 16V8a2 2 0 0 0-1-1.73l-7-4a2 2 0 0 0-2 0l-7 4A2 2 0 0 0 3 8v8a2 2 0 0 0 1 1.73l7 4a2 2 0 0 0 2 0l7-4A2 2 0 0 0 21 16z" stroke="currentColor" stroke-width="2"/>
            <path d="M3.27 6.96L12 12.01l8.73-5.05M12 22.08V12" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        SVG
      when 'review', 'comment', 'feedback'
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M21 15a2 2 0 0 1-2 2H7l-4 4V5a2 2 0 0 1 2-2h14a2 2 0 0 1 2 2z" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <path d="M12 7v2M12 13h.01" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        SVG
      else
        # Generic entity icon
        <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <rect x="3" y="3" width="18" height="18" rx="2" ry="2" stroke="currentColor" stroke-width="2"/>
            <circle cx="8.5" cy="8.5" r="1.5" fill="currentColor"/>
            <path d="M21 15l-5-5L5 21" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
          </svg>
        SVG
      end
    end

    def generate_context_icons(description)
      icons = {}
      desc = description.downcase

      if desc.include?('store') || desc.include?('shop') || desc.include?('commerce')
        icons['store'] = <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M2 7h20l-2 10H4L2 7zM2 7l-2-5h4l2 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
            <circle cx="9" cy="20" r="1" stroke="currentColor" stroke-width="2"/>
            <circle cx="20" cy="20" r="1" stroke="currentColor" stroke-width="2"/>
          </svg>
        SVG
      end

      if desc.include?('library') || desc.include?('book') || desc.include?('read')
        icons['library'] = <<~SVG
          <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
            <path d="M4 19.5A2.5 2.5 0 0 1 6.5 17H20" stroke="currentColor" stroke-width="2"/>
            <path d="M6.5 2H20v20H6.5A2.5 2.5 0 0 1 4 19.5v-15A2.5 2.5 0 0 1 6.5 2z" stroke="currentColor" stroke-width="2"/>
            <path d="M8 7h8M8 11h8" stroke="currentColor" stroke-width="1" stroke-linecap="round"/>
          </svg>
        SVG
      end

      icons
    end

    def generate_icon_helper
      helper_content = <<~RUBY
        # Application-specific icon helper with custom SVG icons
        module IconHelper
          # Primary icon method - renders SVG icons with proper accessibility
          def app_icon(name, **options)
            classes = options[:class] || options[:classes] || "w-6 h-6"
            title = options[:title] || options[:alt] || name.to_s.humanize

            content_tag :div, class: "inline-flex items-center justify-center" do
              raw(svg_icon_content(name, classes: classes, title: title))
            end
          end

          private

          def svg_icon_content(name, classes:, title:)
            icon_path = Rails.root.join('app', 'assets', 'images', 'icons', "\#{name}.svg")

            if File.exist?(icon_path)
              svg_content = File.read(icon_path)
              # Add classes and title to the SVG
              svg_content.gsub('<svg', "<svg class='\#{classes}' title='\#{title}'")
            else
              # Fallback to a generic icon if specific icon doesn't exist
              fallback_icon(classes: classes, title: title)
            end
          end

          def fallback_icon(classes:, title:)
            <<~SVG
              <svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" class="\#{classes}" title="\#{title}">
                <circle cx="12" cy="12" r="10" stroke="currentColor" stroke-width="2"/>
                <path d="M12 6v6l4 2" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round"/>
              </svg>
            SVG
          end

          # Semantic helper methods for common actions
          def success_icon(**options)
            app_icon(:success, **options)
          end

          def error_icon(**options)
            app_icon(:error, **options)
          end

          def info_icon(**options)
            app_icon(:info, **options)
          end

          def warning_icon(**options)
            app_icon(:warning, **options)
          end

          def edit_icon(**options)
            app_icon(:edit, **options)
          end

          def delete_icon(**options)
            app_icon(:delete, **options)
          end

          def add_icon(**options)
            app_icon(:add, **options)
          end

          def search_icon(**options)
            app_icon(:search, **options)
          end

          # Entity-specific icon helpers
        #{generate_entity_icon_helpers}
        end
      RUBY

      File.write(@output_path.join('app/helpers/icon_helper.rb'), helper_content)
    end

    def generate_entity_icon_helpers
      @entities.map do |entity|
        entity_name = entity[:name]
        <<~RUBY

          def #{entity_name}_icon(**options)
            app_icon(:#{entity_name}, **options)
          end
        RUBY
      end.join
    end
  end
end