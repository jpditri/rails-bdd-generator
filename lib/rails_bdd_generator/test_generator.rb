require 'active_support/core_ext/string'

module RailsBddGenerator
  class TestGenerator
    def initialize(entities, relationships, business_rules = [])
      @entities = entities
      @relationships = relationships
      @business_rules = business_rules
    end

    def generate_factory(entity)
      factory_content = <<~RUBY
        # frozen_string_literal: true

        FactoryBot.define do
          factory :#{entity[:name]} do
            #{generate_factory_attributes(entity)}
            #{generate_factory_associations(entity)}

            #{generate_factory_traits(entity)}
          end
        end
      RUBY

      factory_content
    end

    def generate_model_spec(entity)
      spec_content = <<~RUBY
        # frozen_string_literal: true

        require 'rails_helper'

        RSpec.describe #{entity[:name].capitalize}, type: :model do
          subject(:#{entity[:name]}) { build(:#{entity[:name]}) }

          describe 'associations' do
            #{generate_association_tests(entity)}
          end

          describe 'validations' do
            #{generate_validation_tests(entity)}
          end

          describe 'callbacks' do
            #{generate_callback_tests(entity)}
          end

          describe 'scopes' do
            #{generate_scope_tests(entity)}
          end

          describe 'class methods' do
            #{generate_class_method_tests(entity)}
          end

          describe 'instance methods' do
            #{generate_instance_method_tests(entity)}
          end

          describe 'business logic' do
            #{generate_business_logic_tests(entity)}
          end

          describe 'factory' do
            it 'has a valid default factory' do
              expect(build(:#{entity[:name]})).to be_valid
            end

            #{generate_trait_tests(entity)}
          end
        end
      RUBY

      spec_content
    end

    def generate_feature_spec(entity)
      feature_content = <<~RUBY
        # frozen_string_literal: true

        require 'rails_helper'

        RSpec.describe "#{entity[:name].capitalize.pluralize} Management", type: :feature do
          let(:user) { create(:user) }

          before do
            setup_test_environment
            sign_in user
          end

          after do
            cleanup_test_environment
          end

          describe 'listing #{entity[:name].pluralize}' do
            let!(:#{entity[:name].pluralize}) { create_list(:#{entity[:name]}, 3, user: user) }

            it 'displays all #{entity[:name].pluralize}' do
              visit #{entity[:name].pluralize}_path

              #{entity[:name].pluralize}.each do |#{entity[:name]}|
                expect(page).to have_content(#{entity[:name]}.name) if #{entity[:name]}.respond_to?(:name)
              end
            end

            it 'paginates results' do
              create_list(:#{entity[:name]}, 25, user: user)

              visit #{entity[:name].pluralize}_path

              expect(page).to have_css('.pagination')
              expect(page).to have_selector("tr.#{entity[:name]}-row", maximum: 20)
            end
          end

          describe 'creating a new #{entity[:name]}' do
            it 'creates with valid data' do
              visit new_#{entity[:name]}_path

              #{generate_form_fill_steps(entity)}

              click_button 'Create #{entity[:name].capitalize}'

              expect(page).to have_content('#{entity[:name].capitalize} was successfully created')
            end

            it 'shows errors with invalid data' do
              visit new_#{entity[:name]}_path

              click_button 'Create #{entity[:name].capitalize}'

              expect(page).to have_css('.alert-danger')
              expect(page).to have_content("can't be blank")
            end
          end

          describe 'editing a #{entity[:name]}' do
            let(:#{entity[:name]}) { create(:#{entity[:name]}, user: user) }

            it 'updates with valid data' do
              visit edit_#{entity[:name]}_path(#{entity[:name]})

              #{generate_form_update_steps(entity)}

              click_button 'Update #{entity[:name].capitalize}'

              expect(page).to have_content('#{entity[:name].capitalize} was successfully updated')
            end
          end

          describe 'deleting a #{entity[:name]}' do
            let!(:#{entity[:name]}) { create(:#{entity[:name]}, user: user) }

            it 'removes the #{entity[:name]}', js: true do
              visit #{entity[:name].pluralize}_path

              accept_confirm do
                click_link 'Delete', href: #{entity[:name]}_path(#{entity[:name]})
              end

              expect(page).not_to have_content(#{entity[:name]}.name) if #{entity[:name]}.respond_to?(:name)
            end
          end

          describe 'search and filtering' do
            it 'filters by search term' do
              matching = create(:#{entity[:name]}, name: 'Matching Item', user: user)
              non_matching = create(:#{entity[:name]}, name: 'Other Item', user: user)

              visit #{entity[:name].pluralize}_path

              fill_in 'search', with: 'Matching'
              click_button 'Search'

              expect(page).to have_content(matching.name)
              expect(page).not_to have_content(non_matching.name)
            end
          end

          describe 'authorization' do
            let(:other_user) { create(:user) }
            let(:other_#{entity[:name]}) { create(:#{entity[:name]}, user: other_user) }

            it 'prevents access to other users resources' do
              visit #{entity[:name]}_path(other_#{entity[:name]})

              expect(page).to have_content('Not authorized')
            end
          end
        end
      RUBY

      feature_content
    end

    def generate_request_spec(entity)
      request_content = <<~RUBY
        # frozen_string_literal: true

        require 'rails_helper'

        RSpec.describe "/api/v1/#{entity[:name].pluralize}", type: :request do
          let(:user) { create(:user) }
          let(:headers) { { 'Authorization' => "Bearer \#{user.api_token}" } }

          describe 'GET /api/v1/#{entity[:name].pluralize}' do
            let!(:#{entity[:name].pluralize}) { create_list(:#{entity[:name]}, 3) }

            it 'returns all #{entity[:name].pluralize}' do
              get api_v1_#{entity[:name].pluralize}_path, headers: headers

              expect(response).to have_http_status(:success)
              json = JSON.parse(response.body)
              expect(json['#{entity[:name].pluralize}'].size).to eq(3)
            end

            it 'paginates results' do
              create_list(:#{entity[:name]}, 25)

              get api_v1_#{entity[:name].pluralize}_path, params: { page: 2, per_page: 10 }, headers: headers

              json = JSON.parse(response.body)
              expect(json['#{entity[:name].pluralize}'].size).to eq(10)
              expect(json['meta']['current_page']).to eq(2)
            end
          end

          describe 'POST /api/v1/#{entity[:name].pluralize}' do
            let(:valid_params) do
              { #{entity[:name]}: attributes_for(:#{entity[:name]}) }
            end

            let(:invalid_params) do
              { #{entity[:name]}: attributes_for(:#{entity[:name]}, :invalid) }
            end

            context 'with valid parameters' do
              it 'creates a new #{entity[:name]}' do
                expect {
                  post api_v1_#{entity[:name].pluralize}_path, params: valid_params, headers: headers
                }.to change(#{entity[:name].capitalize}, :count).by(1)

                expect(response).to have_http_status(:created)
              end
            end

            context 'with invalid parameters' do
              it 'returns errors' do
                post api_v1_#{entity[:name].pluralize}_path, params: invalid_params, headers: headers

                expect(response).to have_http_status(:unprocessable_entity)
                json = JSON.parse(response.body)
                expect(json['errors']).to be_present
              end
            end
          end

          describe 'authentication' do
            it 'returns unauthorized without token' do
              get api_v1_#{entity[:name].pluralize}_path

              expect(response).to have_http_status(:unauthorized)
            end
          end
        end
      RUBY

      request_content
    end

    private

    def generate_factory_attributes(entity)
      entity[:attributes].map do |attr, type|
        value = case type.to_s
                when /string|text/
                  attr.to_s.include?('email') ? "{ Faker::Internet.email }" : "{ Faker::Lorem.sentence }"
                when /integer/
                  attr.to_s.include?('price') || attr.to_s.include?('amount') ? "{ rand(100..10000) }" : "{ rand(1..100) }"
                when /decimal|float/
                  "{ rand(0.0..100.0).round(2) }"
                when /boolean/
                  "{ [true, false].sample }"
                when /date/
                  "{ Faker::Date.between(from: 1.year.ago, to: Date.today) }"
                when /datetime/
                  "{ Faker::Time.between(from: 1.year.ago, to: Time.now) }"
                else
                  "{ 'default' }"
                end

        "    #{attr} #{value}"
      end.join("\n")
    end

    def generate_factory_associations(entity)
      associations = []

      @relationships.each do |rel|
        if rel[:to] == entity[:name] || rel['to'] == entity[:name]
          from = rel[:from] || rel['from']
          type = rel[:type] || rel['type']

          if type.include?('belongs_to')
            associations << "    association :#{from}"
          end
        end
      end

      associations.join("\n")
    end

    def generate_factory_traits(entity)
      traits = []

      # Generate common traits based on entity attributes
      if entity[:attributes].keys.any? { |k| k.to_s.include?('price') || k.to_s.include?('amount') }
        traits << generate_financial_traits(entity)
      end

      if entity[:attributes].keys.any? { |k| k.to_s.include?('status') || k.to_s.include?('state') }
        traits << generate_status_traits(entity)
      end

      if entity[:attributes].keys.any? { |k| k.to_s.include?('active') || k.to_s.include?('enabled') }
        traits << generate_active_traits(entity)
      end

      # Add testing-specific traits
      traits << <<~RUBY
        trait :invalid do
          #{entity[:attributes].keys.first} { nil }
        end

        trait :for_testing do
          created_at { 1.day.ago }
          updated_at { 1.hour.ago }
        end
      RUBY

      traits.join("\n\n")
    end

    def generate_financial_traits(entity)
      price_attr = entity[:attributes].keys.find { |k| k.to_s.include?('price') || k.to_s.include?('amount') }

      <<~RUBY
        trait :expensive do
          #{price_attr} { 99999 }
        end

        trait :cheap do
          #{price_attr} { 1 }
        end

        trait :free do
          #{price_attr} { 0 }
        end
      RUBY
    end

    def generate_status_traits(entity)
      status_attr = entity[:attributes].keys.find { |k| k.to_s.include?('status') || k.to_s.include?('state') }

      <<~RUBY
        trait :pending do
          #{status_attr} { 'pending' }
        end

        trait :approved do
          #{status_attr} { 'approved' }
        end

        trait :rejected do
          #{status_attr} { 'rejected' }
        end

        trait :completed do
          #{status_attr} { 'completed' }
        end
      RUBY
    end

    def generate_active_traits(entity)
      active_attr = entity[:attributes].keys.find { |k| k.to_s.include?('active') || k.to_s.include?('enabled') }

      <<~RUBY
        trait :active do
          #{active_attr} { true }
        end

        trait :inactive do
          #{active_attr} { false }
        end
      RUBY
    end

    def generate_association_tests(entity)
      tests = []

      @relationships.each do |rel|
        from = rel[:from] || rel['from']
        to = rel[:to] || rel['to']
        type = rel[:type] || rel['type']

        if from == entity[:name]
          case type
          when 'has_many'
            tests << "    it { should have_many(:#{to.pluralize}).dependent(:destroy) }"
          when 'has_one'
            tests << "    it { should have_one(:#{to}).dependent(:destroy) }"
          when 'belongs_to'
            tests << "    it { should belong_to(:#{to}) }"
          when 'has_and_belongs_to_many'
            tests << "    it { should have_and_belong_to_many(:#{to.pluralize}) }"
          end
        elsif to == entity[:name] && type == 'belongs_to'
          tests << "    it { should have_many(:#{from.pluralize}).dependent(:destroy) }"
        end
      end

      tests.empty? ? "    # No associations defined" : tests.join("\n")
    end

    def generate_validation_tests(entity)
      tests = []

      entity[:attributes].each do |attr, type|
        # Common validations based on attribute names
        if attr.to_s.include?('email')
          tests << "    it { should validate_presence_of(:#{attr}) }"
          tests << "    it { should validate_uniqueness_of(:#{attr}).case_insensitive }"
          tests << "    it { should allow_value('user@example.com').for(:#{attr}) }"
          tests << "    it { should_not allow_value('invalid').for(:#{attr}) }"
        elsif %w[name title].include?(attr.to_s)
          tests << "    it { should validate_presence_of(:#{attr}) }"
        elsif type.to_s.include?('integer') || type.to_s.include?('decimal')
          if attr.to_s.include?('price') || attr.to_s.include?('amount')
            tests << "    it { should validate_numericality_of(:#{attr}).is_greater_than_or_equal_to(0) }"
          end
        end
      end

      tests.empty? ? "    # Add validation tests as needed" : tests.join("\n")
    end

    def generate_callback_tests(entity)
      <<~RUBY
        describe 'before_save callbacks' do
          # Add callback tests based on your model implementation
        end

        describe 'after_create callbacks' do
          # Add callback tests based on your model implementation
        end
      RUBY
    end

    def generate_scope_tests(entity)
      <<~RUBY
        describe '.recent' do
          it 'returns records ordered by created_at desc' do
            old = create(:#{entity[:name]}, created_at: 1.week.ago)
            new = create(:#{entity[:name]}, created_at: 1.hour.ago)

            expect(described_class.recent).to eq([new, old])
          end
        end

        describe '.active' do
          it 'returns only active records' do
            active = create(:#{entity[:name]}, :active)
            inactive = create(:#{entity[:name]}, :inactive)

            expect(described_class.active).to include(active)
            expect(described_class.active).not_to include(inactive)
          end
        end if #{entity[:name].capitalize}.column_names.include?('active')
      RUBY
    end

    def generate_class_method_tests(entity)
      <<~RUBY
        describe '.search' do
          it 'finds records matching the search term' do
            matching = create(:#{entity[:name]}, name: 'Searchable Item')
            non_matching = create(:#{entity[:name]}, name: 'Other Item')

            results = described_class.search('Searchable')

            expect(results).to include(matching)
            expect(results).not_to include(non_matching)
          end
        end if #{entity[:name].capitalize}.respond_to?(:search)
      RUBY
    end

    def generate_instance_method_tests(entity)
      <<~RUBY
        describe '#display_name' do
          it 'returns a formatted name' do
            #{entity[:name]} = build(:#{entity[:name]}, name: 'Test Item')
            expect(#{entity[:name]}.display_name).to eq('Test Item')
          end
        end if #{entity[:name]}.new.respond_to?(:display_name)

        describe '#to_s' do
          it 'returns string representation' do
            #{entity[:name]} = build(:#{entity[:name]})
            expect(#{entity[:name]}.to_s).to be_a(String)
          end
        end
      RUBY
    end

    def generate_business_logic_tests(entity)
      # Generate tests based on business rules
      if @business_rules.any? { |rule| rule['entity'] == entity[:name] }
        relevant_rules = @business_rules.select { |rule| rule['entity'] == entity[:name] }

        tests = relevant_rules.map do |rule|
          <<~RUBY
            describe '#{rule['description']}' do
              it 'enforces: #{rule['rule']}' do
                # Implement test for: #{rule['rule']}
                pending 'Business logic test implementation'
              end
            end
          RUBY
        end

        tests.join("\n")
      else
        "    # Add business logic tests as needed"
      end
    end

    def generate_trait_tests(entity)
      <<~RUBY
        it 'has valid traits' do
          expect(build(:#{entity[:name]}, :for_testing)).to be_valid
          expect(build(:#{entity[:name]}, :invalid)).not_to be_valid
        end
      RUBY
    end

    def generate_form_fill_steps(entity)
      steps = []

      entity[:attributes].each do |attr, type|
        next if attr.to_s.include?('_id') # Skip foreign keys

        case type.to_s
        when /string|text/
          steps << "      fill_in '#{attr.to_s.humanize}', with: 'Test #{attr.to_s.humanize}'"
        when /integer|decimal/
          steps << "      fill_in '#{attr.to_s.humanize}', with: '100'"
        when /boolean/
          steps << "      check '#{attr.to_s.humanize}'"
        when /date/
          steps << "      fill_in '#{attr.to_s.humanize}', with: Date.today"
        end
      end

      steps.take(3).join("\n") # Limit to first 3 fields for brevity
    end

    def generate_form_update_steps(entity)
      steps = []

      entity[:attributes].each do |attr, type|
        next if attr.to_s.include?('_id')

        case type.to_s
        when /string|text/
          steps << "      fill_in '#{attr.to_s.humanize}', with: 'Updated #{attr.to_s.humanize}'"
          break # Just update one field for the example
        end
      end

      steps.join("\n")
    end
  end
end