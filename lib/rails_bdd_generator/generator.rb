require 'json'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'active_support/core_ext/string'
require_relative 'llm_designer'
require_relative 'test_generator'
require_relative 'test_helpers'
require_relative 'ux_enhancer'

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

      # Initialize LLM designer if API key is available
      if ENV['ANTHROPIC_API_KEY']
        @llm_designer = LLMDesigner.new
      end
    end

    def generate!
      puts "🚀 Rails BDD Generator v#{VERSION}"
      puts "=" * 60
      puts "📱 Generating: #{@specification['name'] || 'Rails App'}"
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
      enhance_ux
      finalize_application

      puts "\n✅ Rails application generated successfully!"
      puts "📁 Location: #{@output_path}"
      puts "\n📝 Next steps:"
      puts "  cd #{@output_path}"
      puts "  bundle install"
      puts "  rails db:create db:migrate db:seed"
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
          { description: spec }
        end
      else
        raise ArgumentError, "Invalid specification format"
      end
    end

    def analyze_specification
      puts "\n📊 Analyzing specification..."

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
          puts "  ⚠️ LLM design failed: #{e.message}"
          puts "  📝 Falling back to pattern-based extraction..."
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

      # Common entity patterns
      patterns = [
        /(?:manage|track|store)\s+(\w+)/i,
        /(\w+)\s+(?:management|tracking|collection)/i
      ]

      patterns.each do |pattern|
        description.scan(pattern) { |match| entities << normalize_entity(match[0]) }
      end

      entities.uniq { |e| e[:name] }
    end

    def default_attributes
      {
        name: :string,
        description: :text,
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

        ruby '3.3.0'

        gem 'rails', '~> 8.0.0'
        gem 'pg', '~> 1.5'
        gem 'puma', '~> 6.0'
        gem 'bcrypt', '~> 3.1'  # Rails 8 uses bcrypt for authentication
        gem 'rack-cors'
        gem 'active_model_serializers', '~> 0.10'
        gem 'kaminari', '~> 1.2'
        gem 'bootsnap', require: false

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
        app/controllers app/models app/views app/services app/serializers
        app/controllers/api app/controllers/api/v1
        config/initializers
        db/migrate
        features/step_definitions features/support
        spec/models spec/controllers spec/requests spec/factories
        spec/features spec/support spec/integration spec/performance
        lib/tasks
      ]

      dirs.each { |dir| FileUtils.mkdir_p(@output_path.join(dir)) }
    end

    def create_application_files
      # config/application.rb
      app_config = <<~RUBY
        require_relative 'boot'
        require 'rails/all'

        Bundler.require(*Rails.groups)

        module #{app_name}
          class Application < Rails::Application
            config.load_defaults 7.1
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
      puts "\n📦 Generating models..."

      @entities.each do |entity|
        generate_model(entity)
      end

      puts "  ✓ Generated #{@entities.count} models"
    end

    def generate_model(entity)
      model_content = <<~RUBY
        class #{entity[:name].capitalize} < ApplicationRecord
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
      puts "\n🎮 Generating controllers..."

      @entities.each do |entity|
        next if entity[:name] == 'user'
        generate_controller(entity)
      end

      puts "  ✓ Controllers generated"
    end

    def generate_controller(entity)
      controller_content = <<~RUBY
        class #{entity[:name].capitalize.pluralize}Controller < ApplicationController
          before_action :require_authentication  # Rails 8 built-in auth
          before_action :set_#{entity[:name]}, only: %i[show edit update destroy]

          def index
            @#{entity[:name].pluralize} = current_user.#{entity[:name].pluralize}.page(params[:page])
          end

          def show
          end

          def new
            @#{entity[:name]} = current_user.#{entity[:name].pluralize}.build
          end

          def create
            @#{entity[:name]} = current_user.#{entity[:name].pluralize}.build(#{entity[:name]}_params)

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
            @#{entity[:name]} = current_user.#{entity[:name].pluralize}.find(params[:id])
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
      puts "\n🎨 Generating views..."

      @entities.each do |entity|
        next if entity[:name] == 'user'
        generate_views_for_entity(entity)
      end

      puts "  ✓ Views generated"
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
                    <%= link_to 'New #{entity[:name].capitalize}', new_#{entity[:name]}_path, class: 'btn btn-primary' %>
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
                              <%= link_to 'View', #{entity[:name]}, class: 'btn btn-sm btn-outline' %>
                              <%= link_to 'Edit', edit_#{entity[:name]}_path(#{entity[:name]}), class: 'btn btn-sm btn-secondary' %>
                              <%= link_to 'Delete', #{entity[:name]}, method: :delete,
                                  data: { confirm: 'Are you sure?' },
                                  class: 'btn btn-sm btn-danger' %>
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
              <%= link_to 'Edit', edit_#{entity[:name]}_path(@#{entity[:name]}), class: 'btn btn-primary' %>
              <%= link_to 'Delete', #{entity[:name]}_path(@#{entity[:name]}), method: :delete,
                  data: { confirm: 'Are you sure?' }, class: 'btn btn-danger' %>
              <%= link_to 'Back to List', #{entity[:name].pluralize}_path, class: 'btn btn-secondary' %>
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
              <%= link_to 'View', @#{entity[:name]}, class: 'btn btn-outline' %>
              <%= link_to 'Back to List', #{entity[:name].pluralize}_path, class: 'btn btn-secondary' %>
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
        class Create#{entity[:name].capitalize.pluralize} < ActiveRecord::Migration[7.1]
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
          puts "  ⚠️ LLM feature generation failed: #{e.message}"
          puts "  📝 Falling back to template-based generation..."
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

        RSpec.describe #{entity[:name].capitalize.pluralize}Controller, type: :controller do
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

      @entities.each do |entity|
        generate_api_controller(entity)
        generate_serializer(entity)
      end

      puts "  ✓ API layer generated"
    end

    def generate_api_controller(entity)
      api_controller = <<~RUBY
        module Api
          module V1
            class #{entity[:name].capitalize.pluralize}Controller < Api::V1::BaseController
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
      serializer_content = <<~RUBY
        class #{entity[:name].capitalize}Serializer < ActiveModel::Serializer
          attributes :id, #{entity[:attributes].keys.map { |a| ":#{a}" }.join(', ')}, :created_at, :updated_at

          belongs_to :user
        end
      RUBY

      File.write(@output_path.join("app/serializers/#{entity[:name]}_serializer.rb"), serializer_content)
    end

    def enhance_ux
      puts "\n🎨 Enhancing user experience..."

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
      puts "\n🎨 Finalizing application..."

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
          adapter: postgresql
          encoding: unicode
          pool: <%= ENV.fetch("RAILS_MAX_THREADS") { 5 } %>

        development:
          <<: *default
          database: #{app_name}_development

        test:
          <<: *default
          database: #{app_name}_test

        production:
          <<: *default
          database: #{app_name}_production
          username: #{app_name}
          password: <%= ENV['DATABASE_PASSWORD'] %>
      YAML

      File.write(@output_path.join('config/database.yml'), db_config)
    end

    def generate_seeds
      seeds = <<~RUBY
        # Create admin user
        User.create!(
          email: 'admin@example.com',
          password: 'password123',
          first_name: 'Admin',
          last_name: 'User',
          role: 'admin'
        )

        puts "Created admin user: admin@example.com / password123"

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
  end
end