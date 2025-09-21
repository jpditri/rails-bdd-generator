# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Reviews Management", type: :feature do
  let(:user) { create(:user) }

  before do
    setup_test_environment
    sign_in user
  end

  after do
    cleanup_test_environment
  end

  describe 'listing reviews' do
    let!(:reviews) { create_list(:review, 3, user: user) }

    it 'displays all reviews' do
      visit reviews_path

      reviews.each do |review|
        expect(page).to have_content(review.name) if review.respond_to?(:name)
      end
    end

    it 'paginates results' do
      create_list(:review, 25, user: user)

      visit reviews_path

      expect(page).to have_css('.pagination')
      expect(page).to have_selector("tr.review-row", maximum: 20)
    end
  end

  describe 'creating a new review' do
    it 'creates with valid data' do
      visit new_review_path

            fill_in 'Rating', with: '100'
      fill_in 'Title', with: 'Test Title'
      fill_in 'Content', with: 'Test Content'

      click_button 'Create Review'

      expect(page).to have_content('Review was successfully created')
    end

    it 'shows errors with invalid data' do
      visit new_review_path

      click_button 'Create Review'

      expect(page).to have_css('.alert-danger')
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'editing a review' do
    let(:review) { create(:review, user: user) }

    it 'updates with valid data' do
      visit edit_review_path(review)

            fill_in 'Title', with: 'Updated Title'

      click_button 'Update Review'

      expect(page).to have_content('Review was successfully updated')
    end
  end

  describe 'deleting a review' do
    let!(:review) { create(:review, user: user) }

    it 'removes the review', js: true do
      visit reviews_path

      accept_confirm do
        click_link 'Delete', href: review_path(review)
      end

      expect(page).not_to have_content(review.name) if review.respond_to?(:name)
    end
  end

  describe 'search and filtering' do
    it 'filters by search term' do
      matching = create(:review, name: 'Matching Item', user: user)
      non_matching = create(:review, name: 'Other Item', user: user)

      visit reviews_path

      fill_in 'search', with: 'Matching'
      click_button 'Search'

      expect(page).to have_content(matching.name)
      expect(page).not_to have_content(non_matching.name)
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_review) { create(:review, user: other_user) }

    it 'prevents access to other users resources' do
      visit review_path(other_review)

      expect(page).to have_content('Not authorized')
    end
  end
end
