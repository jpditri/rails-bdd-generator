# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Orders Management", type: :feature do
  let(:user) { create(:user) }

  before do
    setup_test_environment
    sign_in user
  end

  after do
    cleanup_test_environment
  end

  describe 'listing orders' do
    let!(:orders) { create_list(:order, 3, user: user) }

    it 'displays all orders' do
      visit orders_path

      orders.each do |order|
        expect(page).to have_content(order.name) if order.respond_to?(:name)
      end
    end

    it 'paginates results' do
      create_list(:order, 25, user: user)

      visit orders_path

      expect(page).to have_css('.pagination')
      expect(page).to have_selector("tr.order-row", maximum: 20)
    end
  end

  describe 'creating a new order' do
    it 'creates with valid data' do
      visit new_order_path

            fill_in 'Order number', with: 'Test Order number'
      fill_in 'Total amount', with: '100'
      fill_in 'Status', with: 'Test Status'

      click_button 'Create Order'

      expect(page).to have_content('Order was successfully created')
    end

    it 'shows errors with invalid data' do
      visit new_order_path

      click_button 'Create Order'

      expect(page).to have_css('.alert-danger')
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'editing a order' do
    let(:order) { create(:order, user: user) }

    it 'updates with valid data' do
      visit edit_order_path(order)

            fill_in 'Order number', with: 'Updated Order number'

      click_button 'Update Order'

      expect(page).to have_content('Order was successfully updated')
    end
  end

  describe 'deleting a order' do
    let!(:order) { create(:order, user: user) }

    it 'removes the order', js: true do
      visit orders_path

      accept_confirm do
        click_link 'Delete', href: order_path(order)
      end

      expect(page).not_to have_content(order.name) if order.respond_to?(:name)
    end
  end

  describe 'search and filtering' do
    it 'filters by search term' do
      matching = create(:order, name: 'Matching Item', user: user)
      non_matching = create(:order, name: 'Other Item', user: user)

      visit orders_path

      fill_in 'search', with: 'Matching'
      click_button 'Search'

      expect(page).to have_content(matching.name)
      expect(page).not_to have_content(non_matching.name)
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_order) { create(:order, user: other_user) }

    it 'prevents access to other users resources' do
      visit order_path(other_order)

      expect(page).to have_content('Not authorized')
    end
  end
end
