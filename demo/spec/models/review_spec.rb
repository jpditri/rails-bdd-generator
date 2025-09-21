# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Review, type: :model do
  subject(:review) { build(:review) }

  describe 'associations' do
        it { should belong_to(:book) }
    it { should belong_to(:user) }
  end

  describe 'validations' do
        it { should validate_presence_of(:title) }
  end

  describe 'callbacks' do
    describe 'before_save callbacks' do
  # Add callback tests based on your model implementation
end

describe 'after_create callbacks' do
  # Add callback tests based on your model implementation
end

  end

  describe 'scopes' do
    describe '.recent' do
  it 'returns records ordered by created_at desc' do
    old = create(:review, created_at: 1.week.ago)
    new = create(:review, created_at: 1.hour.ago)

    expect(described_class.recent).to eq([new, old])
  end
end

describe '.active' do
  it 'returns only active records' do
    active = create(:review, :active)
    inactive = create(:review, :inactive)

    expect(described_class.active).to include(active)
    expect(described_class.active).not_to include(inactive)
  end
end if Review.column_names.include?('active')

  end

  describe 'class methods' do
    describe '.search' do
  it 'finds records matching the search term' do
    matching = create(:review, name: 'Searchable Item')
    non_matching = create(:review, name: 'Other Item')

    results = described_class.search('Searchable')

    expect(results).to include(matching)
    expect(results).not_to include(non_matching)
  end
end if Review.respond_to?(:search)

  end

  describe 'instance methods' do
    describe '#display_name' do
  it 'returns a formatted name' do
    review = build(:review, name: 'Test Item')
    expect(review.display_name).to eq('Test Item')
  end
end if review.new.respond_to?(:display_name)

describe '#to_s' do
  it 'returns string representation' do
    review = build(:review)
    expect(review.to_s).to be_a(String)
  end
end

  end

  describe 'business logic' do
    describe 'Rating validation' do
  it 'enforces: Rating must be between 1 and 5' do
    # Implement test for: Rating must be between 1 and 5
    pending 'Business logic test implementation'
  end
end

  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:review)).to be_valid
    end

    it 'has valid traits' do
  expect(build(:review, :for_testing)).to be_valid
  expect(build(:review, :invalid)).not_to be_valid
end

  end
end
