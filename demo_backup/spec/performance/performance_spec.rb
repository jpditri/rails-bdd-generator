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
    `ps -o rss= -p #{Process.pid}`.to_i * 1024 # Convert KB to bytes
  end
end
