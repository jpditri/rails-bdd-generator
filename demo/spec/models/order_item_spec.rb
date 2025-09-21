# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Order_item, type: :model do
  subject(:order_item) { build(:order_item) }

  describe 'associations' do
        it { should belong_to(:book) }
    it { should belong_to(:order) }
  end

  describe 'validations' do
        it { should validate_numericality_of(:unit_price).is_greater_than_or_equal_to(0) }
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
    old = create(:order_item, created_at: 1.week.ago)
    new = create(:order_item, created_at: 1.hour.ago)

    expect(described_class.recent).to eq([new, old])
  end
end

describe '.active' do
  it 'returns only active records' do
    active = create(:order_item, :active)
    inactive = create(:order_item, :inactive)

    expect(described_class.active).to include(active)
    expect(described_class.active).not_to include(inactive)
  end
end if Order_item.column_names.include?('active')

  end

  describe 'class methods' do
    describe '.search' do
  it 'finds records matching the search term' do
    matching = create(:order_item, name: 'Searchable Item')
    non_matching = create(:order_item, name: 'Other Item')

    results = described_class.search('Searchable')

    expect(results).to include(matching)
    expect(results).not_to include(non_matching)
  end
end if Order_item.respond_to?(:search)

  end

  describe 'instance methods' do
    describe '#display_name' do
  it 'returns a formatted name' do
    order_item = build(:order_item, name: 'Test Item')
    expect(order_item.display_name).to eq('Test Item')
  end
end if order_item.new.respond_to?(:display_name)

describe '#to_s' do
  it 'returns string representation' do
    order_item = build(:order_item)
    expect(order_item.to_s).to be_a(String)
  end
end

  end

  describe 'business logic' do
        # Add business logic tests as needed
  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:order_item)).to be_valid
    end

    it 'has valid traits' do
  expect(build(:order_item, :for_testing)).to be_valid
  expect(build(:order_item, :invalid)).not_to be_valid
end

  end
end
