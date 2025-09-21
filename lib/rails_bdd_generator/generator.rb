require 'json'
require 'yaml'
require 'fileutils'
require 'pathname'
require 'active_support/core_ext/string'

module RailsBddGenerator
  class Generator
    attr_reader :specification, :entities, :features, :output_path

    def initialize(specification, output_path: nil)
      @specification = parse_specification(specification)
      @output_path = output_path || Pathname.pwd.join('generated_app')
      @entities = []
      @features = []
      @migrations = []
      @tests = []
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
          gem 'shoulda-matchers', '~> 5.0'
          gem 'capybara'
          gem 'selenium-webdriver'
          gem 'simplecov'
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
        <h1>#{entity[:name].capitalize.pluralize}</h1>

        <%= link_to 'New #{entity[:name].capitalize}', new_#{entity[:name]}_path, class: 'btn btn-primary' %>

        <table class="table">
          <thead>
            <tr>
              #{entity[:attributes].keys.take(3).map { |a| "<th>#{a.to_s.humanize}</th>" }.join("\n      ")}
              <th>Actions</th>
            </tr>
          </thead>
          <tbody>
            <% @#{entity[:name].pluralize}.each do |#{entity[:name]}| %>
              <tr>
                #{entity[:attributes].keys.take(3).map { |a| "<td><%= #{entity[:name]}.#{a} %></td>" }.join("\n        ")}
                <td>
                  <%= link_to 'Show', #{entity[:name]} %>
                  <%= link_to 'Edit', edit_#{entity[:name]}_path(#{entity[:name]}) %>
                  <%= link_to 'Delete', #{entity[:name]}, method: :delete, data: { confirm: 'Are you sure?' } %>
                </td>
              </tr>
            <% end %>
          </tbody>
        </table>

        <%= paginate @#{entity[:name].pluralize} %>
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
        <h1>#{entity[:name].capitalize}</h1>

        #{entity[:attributes].map { |a, _| "<p><strong>#{a.to_s.humanize}:</strong> <%= @#{entity[:name]}.#{a} %></p>" }.join("\n")}

        <%= link_to 'Edit', edit_#{entity[:name]}_path(@#{entity[:name]}), class: 'btn btn-primary' %>
        <%= link_to 'Back', #{entity[:name].pluralize}_path, class: 'btn btn-secondary' %>
      ERB
    end

    def new_view_template(entity)
      <<~ERB
        <h1>New #{entity[:name].capitalize}</h1>

        <%= render 'form', #{entity[:name]}: @#{entity[:name]} %>

        <%= link_to 'Back', #{entity[:name].pluralize}_path %>
      ERB
    end

    def edit_view_template(entity)
      <<~ERB
        <h1>Edit #{entity[:name].capitalize}</h1>

        <%= render 'form', #{entity[:name]}: @#{entity[:name]} %>

        <%= link_to 'Show', @#{entity[:name]} %> |
        <%= link_to 'Back', #{entity[:name].pluralize}_path %>
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

      @entities.each do |entity|
        generate_feature(entity)
      end

      puts "  ✓ Generated #{@entities.count} features"
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

      @entities.each do |entity|
        generate_model_spec(entity)
        generate_controller_spec(entity)
      end

      puts "  ✓ Generated test specs"
    end

    def generate_model_spec(entity)
      spec_content = <<~RUBY
        require 'rails_helper'

        RSpec.describe #{entity[:name].capitalize}, type: :model do
          describe 'associations' do
            #{generate_association_tests(entity)}
          end

          describe 'validations' do
            #{generate_validation_tests(entity)}
          end

          describe 'scopes' do
            describe '.active' do
              it 'returns active records' do
                active = create(:#{entity[:name]}, active: true)
                inactive = create(:#{entity[:name]}, active: false)

                expect(described_class.active).to include(active)
                expect(described_class.active).not_to include(inactive)
              end
            end
          end
        end
      RUBY

      File.write(@output_path.join("spec/models/#{entity[:name]}_spec.rb"), spec_content)
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
  end
end