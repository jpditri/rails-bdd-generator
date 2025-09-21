# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "Books Management", type: :feature do
  let(:user) { create(:user) }

  before do
    setup_test_environment
    sign_in user
  end

  after do
    cleanup_test_environment
  end

  describe 'listing books' do
    let!(:books) { create_list(:book, 3, user: user) }

    it 'displays all books' do
      visit books_path

      books.each do |book|
        expect(page).to have_content(book.name) if book.respond_to?(:name)
      end
    end

    it 'paginates results' do
      create_list(:book, 25, user: user)

      visit books_path

      expect(page).to have_css('.pagination')
      expect(page).to have_selector("tr.book-row", maximum: 20)
    end
  end

  describe 'creating a new book' do
    it 'creates with valid data' do
      visit new_book_path

            fill_in 'Title', with: 'Test Title'
      fill_in 'Author', with: 'Test Author'
      fill_in 'Isbn', with: 'Test Isbn'

      click_button 'Create Book'

      expect(page).to have_content('Book was successfully created')
    end

    it 'shows errors with invalid data' do
      visit new_book_path

      click_button 'Create Book'

      expect(page).to have_css('.alert-danger')
      expect(page).to have_content("can't be blank")
    end
  end

  describe 'editing a book' do
    let(:book) { create(:book, user: user) }

    it 'updates with valid data' do
      visit edit_book_path(book)

            fill_in 'Title', with: 'Updated Title'

      click_button 'Update Book'

      expect(page).to have_content('Book was successfully updated')
    end
  end

  describe 'deleting a book' do
    let!(:book) { create(:book, user: user) }

    it 'removes the book', js: true do
      visit books_path

      accept_confirm do
        click_link 'Delete', href: book_path(book)
      end

      expect(page).not_to have_content(book.name) if book.respond_to?(:name)
    end
  end

  describe 'search and filtering' do
    it 'filters by search term' do
      matching = create(:book, name: 'Matching Item', user: user)
      non_matching = create(:book, name: 'Other Item', user: user)

      visit books_path

      fill_in 'search', with: 'Matching'
      click_button 'Search'

      expect(page).to have_content(matching.name)
      expect(page).not_to have_content(non_matching.name)
    end
  end

  describe 'authorization' do
    let(:other_user) { create(:user) }
    let(:other_book) { create(:book, user: other_user) }

    it 'prevents access to other users resources' do
      visit book_path(other_book)

      expect(page).to have_content('Not authorized')
    end
  end
end
