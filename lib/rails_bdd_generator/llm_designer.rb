require 'net/http'
require 'json'
require 'uri'

module RailsBddGenerator
  class LLMDesigner
    ANTHROPIC_API_URL = 'https://api.anthropic.com/v1/messages'

    def initialize(api_key = nil)
      @api_key = api_key || ENV['ANTHROPIC_API_KEY']
      raise "ANTHROPIC_API_KEY environment variable not set" unless @api_key
    end

    def design_application(description)
      prompt = build_design_prompt(description)
      response = call_claude(prompt)
      parse_design_response(response)
    end

    def generate_cucumber_features(entities, relationships, business_rules)
      prompt = build_cucumber_prompt(entities, relationships, business_rules)
      response = call_claude(prompt)
      parse_cucumber_response(response)
    end

    def generate_implementation_code(feature, entities)
      prompt = build_implementation_prompt(feature, entities)
      response = call_claude(prompt)
      parse_implementation_response(response)
    end

    private

    def build_design_prompt(description)
      <<~PROMPT
        You are an expert Rails application architect. Design a complete Rails 8 application based on this description:

        "#{description}"

        Provide a detailed JSON response with the following structure:
        {
          "name": "ApplicationName",
          "description": "Enhanced description",
          "entities": [
            {
              "name": "entity_name",
              "attributes": {
                "attribute_name": "type",
                ...
              },
              "validations": ["validation rules"],
              "business_logic": ["business rules for this entity"]
            }
          ],
          "relationships": [
            {
              "from": "entity1",
              "to": "entity2",
              "type": "has_many|belongs_to|has_one|has_and_belongs_to_many",
              "through": "join_table (if applicable)",
              "dependent": "destroy|nullify|restrict",
              "inverse_of": "relationship_name"
            }
          ],
          "business_rules": [
            "Clear business rule statements"
          ],
          "features": [
            {
              "name": "feature_name",
              "description": "what this feature does",
              "user_stories": ["As a..., I want..., So that..."]
            }
          ],
          "api_endpoints": [
            {
              "path": "/api/v1/resource",
              "method": "GET|POST|PUT|DELETE",
              "description": "what this endpoint does",
              "authentication": "required|optional|none"
            }
          ],
          "background_jobs": [
            {
              "name": "JobName",
              "description": "what this job does",
              "schedule": "cron expression or trigger"
            }
          ],
          "security_considerations": [
            "Security measures to implement"
          ]
        }

        Think step by step:
        1. What are the core entities needed?
        2. What attributes should each entity have?
        3. How do entities relate to each other?
        4. What business rules govern the system?
        5. What features would users need?
        6. What API endpoints are necessary?
        7. What background processing is needed?
        8. What security measures should be in place?

        Provide comprehensive, production-ready design. Be specific and detailed.
      PROMPT
    end

    def build_cucumber_prompt(entities, relationships, business_rules)
      <<~PROMPT
        You are an expert in Behavior-Driven Development. Create comprehensive Cucumber features for a Rails application with:

        Entities: #{entities.map { |e| e[:name] }.join(', ')}

        Relationships:
        #{relationships.map { |r| "#{r[:from]} #{r[:type]} #{r[:to]}" }.join("\n")}

        Business Rules:
        #{business_rules.join("\n")}

        Generate detailed Cucumber features following this structure:
        {
          "features": [
            {
              "name": "feature_name",
              "content": "Complete feature file content with multiple scenarios",
              "step_definitions": "Ruby step definitions for this feature",
              "test_data": "Factory Bot factories needed"
            }
          ]
        }

        Include:
        - Happy path scenarios
        - Edge cases
        - Error scenarios
        - Security scenarios
        - Performance considerations
        - Data validation scenarios

        Make features comprehensive and production-ready.
      PROMPT
    end

    def build_implementation_prompt(feature, entities)
      <<~PROMPT
        You are an expert Rails developer. Generate the complete implementation for this Cucumber feature:

        Feature: #{feature[:name]}
        #{feature[:content]}

        Related entities: #{entities.map { |e| e[:name] }.join(', ')}

        Generate a JSON response with:
        {
          "controllers": [
            {
              "name": "ControllerName",
              "code": "Complete controller code"
            }
          ],
          "models": [
            {
              "name": "ModelName",
              "code": "Complete model code with validations, scopes, methods"
            }
          ],
          "views": [
            {
              "path": "views/resource/action.html.erb",
              "code": "Complete ERB template"
            }
          ],
          "migrations": [
            {
              "name": "CreateTableName",
              "code": "Complete migration code"
            }
          ],
          "services": [
            {
              "name": "ServiceName",
              "code": "Service object code if needed"
            }
          ],
          "jobs": [
            {
              "name": "JobName",
              "code": "Background job code if needed"
            }
          ],
          "tests": {
            "models": [{"name": "model_spec.rb", "code": "RSpec code"}],
            "controllers": [{"name": "controller_spec.rb", "code": "RSpec code"}],
            "requests": [{"name": "api_spec.rb", "code": "Request spec code"}]
          }
        }

        Follow Rails 8 best practices:
        - Use Rails 8 built-in authentication
        - Strong parameters
        - Proper error handling
        - N+1 query prevention
        - Security best practices
        - RESTful design
        - DRY principle
      PROMPT
    end

    def call_claude(prompt)
      uri = URI(ANTHROPIC_API_URL)
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.read_timeout = 120
      http.open_timeout = 10

      request = Net::HTTP::Post.new(uri)
      request['Content-Type'] = 'application/json'
      request['X-API-Key'] = @api_key
      request['anthropic-version'] = '2023-06-01'

      request.body = {
        model: 'claude-3-opus-20240229',
        max_tokens: 4096,
        messages: [
          {
            role: 'user',
            content: prompt
          }
        ],
        temperature: 0.7
      }.to_json

      begin
        response = http.request(request)

        if response.code == '200'
          JSON.parse(response.body)
        else
          raise "API call failed: #{response.code} - #{response.body}"
        end
      rescue => e
        raise "Failed to call Claude API: #{e.message}"
      end
    end

    def parse_design_response(response)
      content = response.dig('content', 0, 'text')

      # Extract JSON from the response
      json_match = content.match(/\{.*\}/m)

      if json_match
        # Clean invalid control characters from JSON
        cleaned_json = json_match[0].gsub(/[\x00-\x1f\x7f]/, ' ')
        JSON.parse(cleaned_json)
      else
        # Fallback to basic parsing if no JSON found
        {
          'name' => 'RailsApp',
          'description' => content.lines.first&.strip || 'Rails application',
          'entities' => extract_entities_from_text(content),
          'relationships' => [],
          'business_rules' => extract_business_rules_from_text(content)
        }
      end
    rescue JSON::ParserError => e
      puts "Warning: Could not parse LLM response as JSON: #{e.message}"
      # Return a basic structure
      {
        'name' => 'RailsApp',
        'description' => 'Rails application',
        'entities' => [],
        'relationships' => [],
        'business_rules' => []
      }
    end

    def parse_cucumber_response(response)
      content = response.dig('content', 0, 'text')

      json_match = content.match(/\{.*\}/m)

      if json_match
        # Clean invalid control characters from JSON
        cleaned_json = json_match[0].gsub(/[\x00-\x1f\x7f]/, ' ')
        JSON.parse(cleaned_json)
      else
        # Parse raw cucumber feature text
        features = content.split(/^Feature:/).reject(&:empty?)
        {
          'features' => features.map do |feature|
            {
              'name' => feature.lines.first&.strip || 'Feature',
              'content' => "Feature: #{feature}",
              'step_definitions' => ''
            }
          end
        }
      end
    rescue JSON::ParserError => e
      puts "Warning: Error parsing Cucumber response: #{e.message}"
      # Try to extract features from text even if JSON is malformed
      parse_features_from_text(content)
    rescue => e
      puts "Warning: Unexpected error parsing response: #{e.message}"
      { 'features' => [] }
    end

    def parse_features_from_text(content)
      features = []

      # Try to extract feature blocks even from malformed JSON
      content.scan(/"name"\s*:\s*"([^"]+)".*?"content"\s*:\s*"((?:[^"]|\\")+)"/m) do |name, feature_content|
        features << {
          'name' => name,
          'content' => feature_content.gsub(/\\n/, "\n").gsub(/\\"/, '"'),
          'step_definitions' => ''
        }
      end

      if features.empty?
        # Fallback to simple feature extraction
        content.split(/Feature:/).reject(&:empty?).each do |feature|
          features << {
            'name' => feature.lines.first&.strip || 'Feature',
            'content' => "Feature: #{feature}",
            'step_definitions' => ''
          }
        end
      end

      { 'features' => features }
    end

    def parse_implementation_response(response)
      content = response.dig('content', 0, 'text')

      json_match = content.match(/\{.*\}/m)

      if json_match
        # Clean invalid control characters from JSON
        cleaned_json = json_match[0].gsub(/[\x00-\x1f\x7f]/, ' ')
        JSON.parse(cleaned_json)
      else
        # Parse code blocks from the response
        extract_code_blocks_from_text(content)
      end
    rescue => e
      puts "Warning: Error parsing implementation response: #{e.message}"
      {
        'controllers' => [],
        'models' => [],
        'views' => [],
        'migrations' => [],
        'tests' => {}
      }
    end

    def extract_entities_from_text(text)
      # Basic entity extraction as fallback
      entities = []

      text.scan(/(?:model|entity|resource|table)\s+(\w+)/i) do |match|
        entities << {
          'name' => match[0].downcase,
          'attributes' => {
            'name' => 'string',
            'description' => 'text'
          }
        }
      end

      entities.uniq { |e| e['name'] }
    end

    def extract_business_rules_from_text(text)
      rules = []

      text.lines.each do |line|
        if line =~ /(?:must|should|needs?|requires?|validates?)/i
          rules << line.strip
        end
      end

      rules.take(10)  # Limit to 10 rules
    end

    def extract_code_blocks_from_text(text)
      result = {
        'controllers' => [],
        'models' => [],
        'views' => [],
        'migrations' => [],
        'tests' => { 'models' => [], 'controllers' => [] }
      }

      current_section = nil
      current_code = []

      text.lines.each do |line|
        if line =~ /^```ruby/
          current_code = []
        elsif line =~ /^```$/
          # Save the accumulated code
          if current_section && !current_code.empty?
            code_content = current_code.join

            case current_section
            when /controller/i
              result['controllers'] << { 'name' => 'Controller', 'code' => code_content }
            when /model/i
              result['models'] << { 'name' => 'Model', 'code' => code_content }
            when /migration/i
              result['migrations'] << { 'name' => 'Migration', 'code' => code_content }
            when /view|template/i
              result['views'] << { 'path' => 'view.html.erb', 'code' => code_content }
            when /spec|test/i
              if current_section =~ /model/i
                result['tests']['models'] << { 'name' => 'spec.rb', 'code' => code_content }
              else
                result['tests']['controllers'] << { 'name' => 'spec.rb', 'code' => code_content }
              end
            end
          end
          current_code = []
        elsif !current_code.nil?
          current_code << line
        elsif line =~ /(controller|model|migration|view|spec|test)/i
          current_section = line
        end
      end

      result
    end
  end
end