Feature: Book Management
  As a user
  I want to manage books
  So that I can organize my data

  Background:
    Given I am logged in as a user

  Scenario: Creating a new book
    When I go to the new book page
    And I fill in the form with valid data
    And I click "Create Book"
    Then I should see "Book created successfully"

  Scenario: Viewing a book
    Given a book exists
    When I go to the book page
    Then I should see the book details

  Scenario: Editing a book
    Given a book exists
    When I go to the edit book page
    And I update the form
    And I click "Update Book"
    Then I should see "Book updated successfully"

  Scenario: Deleting a book
    Given a book exists
    When I go to the books page
    And I click "Delete"
    Then I should see "Book deleted successfully"
