# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Users Management", type: :feature do
  let(:user) { create(:user) }

  before do
    setup_test_environment
    sign_in user
  end

  after do
    cleanup_test_environment
  end

  describe 'listing users' do
    let!(:users) { create_list(:user, 3, user: user) }

    it 'displays all users' do
      visit users_path

      users.each do |user|
        expect(page).to have_content(user.name) if user.respond_to?(:name)
      end
    end

    it 'paginates results' do
      create_list(:user, 25, user: user)

      visit users_path

      expect(page).to have_css('.pagination')
      expect(page).to have_selector("tr.user-row", maximum: 20)
    end
  end

  describe 'creating a new user' do
    it 'creates with valid data' do
      visit new_user_path

            fill_in 'Email', with: 'Test Email'
      fill_in 'First name', with: 'Test First name'
      fill_in 'Last name', with: 'Test Last name'

      click_button 'Create User'

      expect(page).to have_content('User was successfully created')
    end

    it 'shows errors with invalid data' do
      visit new_user_path

      click_button 'Create User'

      expect(page).to have_css('.alert-danger')
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'editing a user' do
    let(:user) { create(:user, user: user) }

    it 'updates with valid data' do
      visit edit_user_path(user)

            fill_in 'Email', with: 'Updated Email'

      click_button 'Update User'

      expect(page).to have_content('User was successfully updated')
    end
  end

  describe 'deleting a user' do
    let!(:user) { create(:user, user: user) }

    it 'removes the user', js: true do
      visit users_path

      accept_confirm do
        click_link 'Delete', href: user_path(user)
      end

      expect(page).not_to have_content(user.name) if user.respond_to?(:name)
    end
  end

  describe 'search and filtering' do
    it 'filters by search term' do
      matching = create(:user, name: 'Matching Item', user: user)
      non_matching = create(:user, name: 'Other Item', user: user)

      visit users_path

      fill_in 'search', with: 'Matching'
      click_button 'Search'

      expect(page).to have_content(matching.name)
      expect(page).not_to have_content(non_matching.name)
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_user) { create(:user, user: other_user) }

    it 'prevents access to other users resources' do
      visit user_path(other_user)

      expect(page).to have_content('Not authorized')
    end
  end
end
