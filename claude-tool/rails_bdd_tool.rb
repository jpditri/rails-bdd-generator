#!/usr/bin/env ruby

require 'json'
require 'pathname'
require 'stringio'

# Add lib directory to load path
$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'rails_bdd_generator'

# Claude Tool wrapper for Rails BDD Generator
class RailsBddTool
  def self.run(input)
    tool_name = input['tool'] || 'generate_rails_app'
    params = input['params'] || {}

    case tool_name
    when 'generate_rails_app'
      generate_rails_app(params)
    when 'design_rails_app'
      design_rails_app(params)
    else
      { success: false, error: "Unknown tool: #{tool_name}" }
    end
  rescue => e
    { success: false, error: e.message, backtrace: e.backtrace.first(5) }
  end

  private

  def self.generate_rails_app(params)
    # Determine input type
    spec = if params['description']
      params['description']
    elsif params['specification']
      params['specification']
    else
      return { success: false, error: 'Either description or specification is required' }
    end

    output_path = params['output_path'] || './generated_app'
    use_ai = params.fetch('use_ai', true)

    # Temporarily disable AI if requested
    original_api_key = ENV['ANTHROPIC_API_KEY']
    ENV.delete('ANTHROPIC_API_KEY') unless use_ai

    begin
      # Capture output
      output_buffer = []
      original_stdout = $stdout
      $stdout = StringIO.new

      # Generate the application
      result = RailsBddGenerator.generate(spec, output_path: output_path)

      # Get captured output
      generation_output = $stdout.string
      $stdout = original_stdout

      # Parse statistics from output
      entities_count = generation_output.scan(/Found (\d+) entities/).flatten.first&.to_i || 0
      features_count = generation_output.scan(/Generated (\d+) features/).flatten.first&.to_i || 0

      {
        success: true,
        app_path: File.absolute_path(output_path),
        entities_created: entities_count,
        features_generated: features_count,
        next_steps: [
          "cd #{output_path}",
          "bundle install",
          "rails db:create db:migrate db:seed",
          "rails server",
          "# Run tests:",
          "cucumber",
          "rspec"
        ],
        generation_log: generation_output.split("\n").select { |line| line.include?('✓') || line.include?('✅') }
      }
    ensure
      ENV['ANTHROPIC_API_KEY'] = original_api_key if original_api_key
      $stdout = original_stdout if $stdout != original_stdout
    end
  end

  def self.design_rails_app(params)
    description = params['description']
    return { success: false, error: 'Description is required' } unless description

    # Check for API key
    unless ENV['ANTHROPIC_API_KEY']
      return {
        success: false,
        error: 'ANTHROPIC_API_KEY is required for AI design',
        hint: 'Set the environment variable or use specification-based generation'
      }
    end

    begin
      designer = RailsBddGenerator::LLMDesigner.new
      design = designer.design_application(description)

      {
        success: true,
        name: design['name'],
        description: design['description'],
        entities: design['entities'],
        relationships: design['relationships'],
        business_rules: design['business_rules'],
        features: design['features'],
        api_endpoints: design['api_endpoints'],
        background_jobs: design['background_jobs'],
        security_considerations: design['security_considerations']
      }
    rescue => e
      {
        success: false,
        error: "Design failed: #{e.message}",
        hint: 'Check your API key and try again'
      }
    end
  end
end

# CLI interface for testing
if __FILE__ == $0
  if ARGV.empty?
    puts "Rails BDD Generator - Claude Tool"
    puts "================================="
    puts ""
    puts "Usage: ruby rails_bdd_tool.rb <command> [options]"
    puts ""
    puts "Commands:"
    puts "  generate <description>  - Generate a Rails app from description"
    puts "  design <description>    - Design app architecture (AI only)"
    puts "  json                    - Read JSON input from stdin"
    puts "  test                    - Run tool tests"
    puts ""
    puts "Examples:"
    puts "  ruby rails_bdd_tool.rb generate 'Blog with comments'"
    puts "  ruby rails_bdd_tool.rb design 'E-commerce platform'"
    puts "  echo '{\"tool\":\"generate_rails_app\",...}' | ruby rails_bdd_tool.rb json"
    exit
  end

  command = ARGV[0]

  case command
  when 'generate'
    description = ARGV[1] || 'Sample Rails application'
    result = RailsBddTool.run({
      'tool' => 'generate_rails_app',
      'params' => {
        'description' => description,
        'output_path' => "./generated_#{Time.now.to_i}"
      }
    })
    puts JSON.pretty_generate(result)

  when 'design'
    description = ARGV[1] || 'Sample Rails application'
    result = RailsBddTool.run({
      'tool' => 'design_rails_app',
      'params' => {
        'description' => description
      }
    })
    puts JSON.pretty_generate(result)

  when 'json'
    # Read JSON from stdin
    input = JSON.parse($stdin.read)
    result = RailsBddTool.run(input)
    puts JSON.generate(result)

  when 'test'
    puts "Testing Rails BDD Tool..."

    # Test generation
    test_input = {
      'tool' => 'generate_rails_app',
      'params' => {
        'description' => 'Simple todo list',
        'output_path' => '/tmp/test_todo_app',
        'use_ai' => false
      }
    }

    result = RailsBddTool.run(test_input)

    if result[:success]
      puts "✅ Tool test passed!"
      puts "Generated app at: #{result[:app_path]}"
    else
      puts "❌ Tool test failed: #{result[:error]}"
    end

  else
    puts "Unknown command: #{command}"
  end
end