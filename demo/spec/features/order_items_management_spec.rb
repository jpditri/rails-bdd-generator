# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Order_items Management", type: :feature do
  let(:user) { create(:user) }

  before do
    setup_test_environment
    sign_in user
  end

  after do
    cleanup_test_environment
  end

  describe 'listing order_items' do
    let!(:order_items) { create_list(:order_item, 3, user: user) }

    it 'displays all order_items' do
      visit order_items_path

      order_items.each do |order_item|
        expect(page).to have_content(order_item.name) if order_item.respond_to?(:name)
      end
    end

    it 'paginates results' do
      create_list(:order_item, 25, user: user)

      visit order_items_path

      expect(page).to have_css('.pagination')
      expect(page).to have_selector("tr.order_item-row", maximum: 20)
    end
  end

  describe 'creating a new order_item' do
    it 'creates with valid data' do
      visit new_order_item_path

            fill_in 'Quantity', with: '100'
      fill_in 'Unit price', with: '100'
      fill_in 'Subtotal', with: '100'

      click_button 'Create Order_item'

      expect(page).to have_content('Order_item was successfully created')
    end

    it 'shows errors with invalid data' do
      visit new_order_item_path

      click_button 'Create Order_item'

      expect(page).to have_css('.alert-danger')
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'editing a order_item' do
    let(:order_item) { create(:order_item, user: user) }

    it 'updates with valid data' do
      visit edit_order_item_path(order_item)

      

      click_button 'Update Order_item'

      expect(page).to have_content('Order_item was successfully updated')
    end
  end

  describe 'deleting a order_item' do
    let!(:order_item) { create(:order_item, user: user) }

    it 'removes the order_item', js: true do
      visit order_items_path

      accept_confirm do
        click_link 'Delete', href: order_item_path(order_item)
      end

      expect(page).not_to have_content(order_item.name) if order_item.respond_to?(:name)
    end
  end

  describe 'search and filtering' do
    it 'filters by search term' do
      matching = create(:order_item, name: 'Matching Item', user: user)
      non_matching = create(:order_item, name: 'Other Item', user: user)

      visit order_items_path

      fill_in 'search', with: 'Matching'
      click_button 'Search'

      expect(page).to have_content(matching.name)
      expect(page).not_to have_content(non_matching.name)
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_order_item) { create(:order_item, user: other_user) }

    it 'prevents access to other users resources' do
      visit order_item_path(other_order_item)

      expect(page).to have_content('Not authorized')
    end
  end
end
