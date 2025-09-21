# frozen_string_literal: true

require 'rails_helper'

RSpec.describe User, type: :model do
  subject(:user) { build(:user) }

  describe 'associations' do
        it { should have_many(:orders).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
    it { should have_many(:reviews).dependent(:destroy) }
  end

  describe 'validations' do
        it { should validate_presence_of(:email) }
    it { should validate_uniqueness_of(:email).case_insensitive }
    it { should allow_value('user@example.com').for(:email) }
    it { should_not allow_value('invalid').for(:email) }
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
    old = create(:user, created_at: 1.week.ago)
    new = create(:user, created_at: 1.hour.ago)

    expect(described_class.recent).to eq([new, old])
  end
end

describe '.active' do
  it 'returns only active records' do
    active = create(:user, :active)
    inactive = create(:user, :inactive)

    expect(described_class.active).to include(active)
    expect(described_class.active).not_to include(inactive)
  end
end if User.column_names.include?('active')

  end

  describe 'class methods' do
    describe '.search' do
  it 'finds records matching the search term' do
    matching = create(:user, name: 'Searchable Item')
    non_matching = create(:user, name: 'Other Item')

    results = described_class.search('Searchable')

    expect(results).to include(matching)
    expect(results).not_to include(non_matching)
  end
end if User.respond_to?(:search)

  end

  describe 'instance methods' do
    describe '#display_name' do
  it 'returns a formatted name' do
    user = build(:user, name: 'Test Item')
    expect(user.display_name).to eq('Test Item')
  end
end if user.new.respond_to?(:display_name)

describe '#to_s' do
  it 'returns string representation' do
    user = build(:user)
    expect(user.to_s).to be_a(String)
  end
end

  end

  describe 'business logic' do
        # Add business logic tests as needed
  end

  describe 'factory' do
    it 'has a valid default factory' do
      expect(build(:user)).to be_valid
    end

    it 'has valid traits' do
  expect(build(:user, :for_testing)).to be_valid
  expect(build(:user, :invalid)).not_to be_valid
end

  end
end
