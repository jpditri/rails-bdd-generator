# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Book, type: :model do
  subject(:book) { build(:book) }

  describe 'associations' do
        it { should have_many(:order_items).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:order_items).dependent(:destroy) }
  end

  describe 'validations' do
        it { should validate_presence_of(:title) }
    it { should validate_numericality_of(:price).is_greater_than_or_equal_to(0) }
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
    old = create(:book, created_at: 1.week.ago)
    new = create(:book, created_at: 1.hour.ago)

    expect(described_class.recent).to eq([new, old])
  end
end

describe '.active' do
  it 'returns only active records' do
    active = create(:book, :active)
    inactive = create(:book, :inactive)

    expect(described_class.active).to include(active)
    expect(described_class.active).not_to include(inactive)
  end
end if Book.column_names.include?('active')

  end

  describe 'class methods' do
    describe '.search' do
  it 'finds records matching the search term' do
    matching = create(:book, name: 'Searchable Item')
    non_matching = create(:book, name: 'Other Item')

    results = described_class.search('Searchable')

    expect(results).to include(matching)
    expect(results).not_to include(non_matching)
  end
end if Book.respond_to?(:search)

  end

  describe 'instance methods' do
    describe '#display_name' do
  it 'returns a formatted name' do
    book = build(:book, name: 'Test Item')
    expect(book.display_name).to eq('Test Item')
  end
end if book.new.respond_to?(:display_name)

describe '#to_s' do
  it 'returns string representation' do
    book = build(:book)
    expect(book.to_s).to be_a(String)
  end
end

  end

  describe 'business logic' do
    describe 'Price validation' do
  it 'enforces: Price must be greater than zero' do
    # Implement test for: Price must be greater than zero
    pending 'Business logic test implementation'
  end
end

  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:book)).to be_valid
    end

    it 'has valid traits' do
  expect(build(:book, :for_testing)).to be_valid
  expect(build(:book, :invalid)).not_to be_valid
end

  end
end
