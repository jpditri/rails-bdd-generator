module RailsBddGenerator
  class TestHelpers
    def self.generate_rails_helper
      <<~RUBY
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
          config.fixture_path = "\#{::Rails.root}/spec/fixtures"

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
      RUBY
    end

    def self.generate_authentication_helpers
      <<~RUBY
        # frozen_string_literal: true

        module AuthenticationHelpers
          def sign_in(user)
            if respond_to?(:visit)
              # Feature specs - simulate login through UI
              visit login_path
              fill_in 'Email', with: user.email
              fill_in 'Password', with: 'password123'
              click_button 'Sign in'
            else
              # Controller specs - set session
              session[:user_id] = user.id
            end
          end

          def sign_out
            if respond_to?(:visit)
              click_link 'Sign Out'
            else
              session.delete(:user_id)
            end
          end

          def current_user
            @current_user ||= User.find(session[:user_id]) if session[:user_id]
          end
        end
      RUBY
    end

    def self.generate_api_helpers
      <<~RUBY
        # frozen_string_literal: true

        module ApiHelpers
          def json_response
            @json_response ||= JSON.parse(response.body, symbolize_names: true)
          end

          def auth_headers(user)
            {
              'Authorization' => "Bearer \#{user.api_token}",
              'Content-Type' => 'application/json',
              'Accept' => 'application/json'
            }
          end

          def paginated_response?
            json_response.key?(:meta) && json_response[:meta].key?(:current_page)
          end

          def expect_paginated_response(total:, per_page: 20)
            expect(paginated_response?).to be true
            expect(json_response[:meta][:total]).to eq(total)
            expect(json_response[:meta][:per_page]).to eq(per_page)
          end

          def expect_error_response(status:, message: nil)
            expect(response).to have_http_status(status)
            expect(json_response[:errors]).to be_present

            if message
              expect(json_response[:errors]).to include(message)
            end
          end
        end
      RUBY
    end

    def self.generate_oauth_helpers
      <<~RUBY
        # frozen_string_literal: true

        module OAuthHelpers
          def setup_oauth_test_environment
            OmniAuth.config.test_mode = true
            OmniAuth.config.mock_auth[:default] = OmniAuth::AuthHash.new({
              provider: 'github',
              uid: '123456',
              info: {
                name: 'Test User',
                email: 'test@example.com'
              },
              credentials: {
                token: 'mock_token',
                expires_at: Time.now + 1.week
              }
            })
          end

          def cleanup_oauth_test_environment
            OmniAuth.config.test_mode = false
            OmniAuth.config.mock_auth[:default] = nil
          end

          def oauth_link_present?(provider)
            page.has_css?("a[href*='\#{provider}']", wait: 0)
          end

          def simulate_successful_oauth_login(provider)
            OmniAuth.config.add_mock(provider.to_sym, {
              uid: '123456',
              info: {
                name: 'OAuth User',
                email: 'oauth@example.com'
              }
            })

            user = User.find_or_create_by!(email: 'oauth@example.com') do |u|
              u.name = 'OAuth User'
              u.provider = provider.to_s
              u.uid = '123456'
            end

            sign_in(user)
            user
          end

          def simulate_oauth_failure(provider, reason = :invalid_credentials)
            OmniAuth.config.mock_auth[provider.to_sym] = reason
          end
        end
      RUBY
    end

    def self.generate_database_test_resilience
      <<~RUBY
        # frozen_string_literal: true

        require 'rails_helper'

        RSpec.describe 'Database Test Resilience', type: :model do
          describe 'transaction rollback handling' do
            it 'properly rolls back failed transactions' do
              expect {
                ActiveRecord::Base.transaction do
                  User.create!(email: 'test@example.com')
                  raise ActiveRecord::Rollback
                end
              }.not_to change(User, :count)
            end

            it 'handles nested transactions correctly' do
              user_count = User.count

              ActiveRecord::Base.transaction do
                User.create!(email: 'outer@example.com')

                ActiveRecord::Base.transaction(requires_new: true) do
                  User.create!(email: 'inner@example.com')
                  raise ActiveRecord::Rollback
                end

                expect(User.count).to eq(user_count + 1)
              end

              expect(User.count).to eq(user_count + 1)
            end
          end

          describe 'database connection handling' do
            it 'recovers from connection timeouts' do
              # Simulate connection timeout
              allow(ActiveRecord::Base.connection).to receive(:execute).and_raise(ActiveRecord::ConnectionTimeoutError)

              expect {
                User.first
              }.to raise_error(ActiveRecord::ConnectionTimeoutError)

              # Restore connection
              allow(ActiveRecord::Base.connection).to receive(:execute).and_call_original

              expect { User.first }.not_to raise_error
            end

            it 'handles concurrent database access' do
              users = []

              threads = 5.times.map do
                Thread.new do
                  ActiveRecord::Base.connection_pool.with_connection do
                    user = User.create!(email: "user_\#{SecureRandom.hex}@example.com")
                    users << user
                  end
                end
              end

              threads.each(&:join)

              expect(users.size).to eq(5)
              expect(users.map(&:persisted?).all?).to be true
            end
          end

          describe 'data integrity' do
            it 'maintains referential integrity' do
              user = create(:user)
              related_record = create(:post, user: user)

              expect {
                user.destroy
              }.to raise_error(ActiveRecord::InvalidForeignKey)

              expect(User.exists?(user.id)).to be true
            end if defined?(Post)

            it 'handles unique constraint violations gracefully' do
              create(:user, email: 'unique@example.com')

              expect {
                create(:user, email: 'unique@example.com')
              }.to raise_error(ActiveRecord::RecordInvalid)
            end
          end

          describe 'test data cleanup' do
            it 'ensures clean slate between tests' do
              initial_count = User.count

              create_list(:user, 3)
              expect(User.count).to eq(initial_count + 3)

              # This would be in a separate test in reality
              # The database_cleaner gem ensures this starts fresh
              DatabaseCleaner.cleaning do
                expect(User.count).to eq(0)
              end
            end
          end
        end
      RUBY
    end

    def self.generate_performance_test
      <<~RUBY
        # frozen_string_literal: true

        require 'rails_helper'
        require 'benchmark'

        RSpec.describe 'Performance Tests', type: :performance do
          describe 'database queries' do
            it 'uses eager loading to avoid N+1 queries' do
              users = create_list(:user, 10)
              users.each { |u| create_list(:post, 5, user: u) } if defined?(Post)

              # Bad: N+1 queries
              expect {
                User.all.each { |u| u.posts.to_a } if defined?(Post)
              }.to perform_under(100).database_queries if defined?(Post)

              # Good: Eager loading
              expect {
                User.includes(:posts).each { |u| u.posts.to_a } if defined?(Post)
              }.to perform_under(3).database_queries if defined?(Post)
            end
          end

          describe 'response times' do
            let(:user) { create(:user) }

            before { sign_in user }

            it 'renders index page quickly' do
              create_list(:post, 100, user: user) if defined?(Post)

              benchmark = Benchmark.measure do
                get posts_path if defined?(PostsController)
              end

              expect(benchmark.real).to be < 1.0 # Less than 1 second
            end if defined?(PostsController)
          end

          describe 'memory usage' do
            it 'does not leak memory in loops' do
              initial_memory = current_memory_usage

              1000.times do
                user = build(:user)
                user.valid?
              end

              GC.start
              final_memory = current_memory_usage

              # Allow for some variance but detect major leaks
              expect(final_memory - initial_memory).to be < 10_000_000 # 10MB
            end
          end

          private

          def current_memory_usage
            `ps -o rss= -p \#{Process.pid}`.to_i * 1024 # Convert KB to bytes
          end
        end
      RUBY
    end

    def self.generate_shared_examples
      <<~RUBY
        # frozen_string_literal: true

        # Shared examples for common behaviors

        RSpec.shared_examples 'a searchable model' do
          describe '.search' do
            let(:matching) { create(described_class.model_name.singular, name: 'Searchable Item') }
            let(:non_matching) { create(described_class.model_name.singular, name: 'Other Item') }

            it 'finds records matching the search term' do
              results = described_class.search('Searchable')

              expect(results).to include(matching)
              expect(results).not_to include(non_matching)
            end

            it 'is case insensitive' do
              results = described_class.search('searchable')

              expect(results).to include(matching)
            end
          end
        end

        RSpec.shared_examples 'a soft deletable model' do
          let(:instance) { create(described_class.model_name.singular) }

          describe '#soft_delete!' do
            it 'marks record as deleted without destroying it' do
              instance.soft_delete!

              expect(instance.deleted_at).to be_present
              expect(described_class.exists?(instance.id)).to be true
            end
          end

          describe '.active' do
            let(:active) { create(described_class.model_name.singular) }
            let(:deleted) { create(described_class.model_name.singular, deleted_at: Time.current) }

            it 'excludes soft deleted records' do
              expect(described_class.active).to include(active)
              expect(described_class.active).not_to include(deleted)
            end
          end
        end

        RSpec.shared_examples 'an auditable model' do
          let(:user) { create(:user) }
          let(:instance) { create(described_class.model_name.singular) }

          it 'tracks creation' do
            new_instance = build(described_class.model_name.singular)
            new_instance.created_by = user
            new_instance.save!

            expect(new_instance.created_by).to eq(user)
            expect(new_instance.created_at).to be_present
          end

          it 'tracks updates' do
            instance.updated_by = user
            instance.save!

            expect(instance.updated_by).to eq(user)
            expect(instance.updated_at).to be > instance.created_at
          end
        end

        RSpec.shared_examples 'a model with money attributes' do |*attributes|
          attributes.each do |attr|
            describe "#\#{attr}" do
              let(:instance) { build(described_class.model_name.singular) }

              it 'stores as cents integer' do
                instance.send("\#{attr}=", 10.50)
                expect(instance.send("\#{attr}_cents")).to eq(1050)
              end

              it 'returns money object' do
                instance.send("\#{attr}=", 10.50)
                money = instance.send(attr)

                expect(money).to be_a(Money)
                expect(money.to_f).to eq(10.50)
              end
            end
          end
        end
      RUBY
    end
  end
end