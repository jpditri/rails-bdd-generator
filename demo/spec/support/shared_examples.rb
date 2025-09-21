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
    describe "##{attr}" do
      let(:instance) { build(described_class.model_name.singular) }

      it 'stores as cents integer' do
        instance.send("#{attr}=", 10.50)
        expect(instance.send("#{attr}_cents")).to eq(1050)
      end

      it 'returns money object' do
        instance.send("#{attr}=", 10.50)
        money = instance.send(attr)

        expect(money).to be_a(Money)
        expect(money.to_f).to eq(10.50)
      end
    end
  end
end
