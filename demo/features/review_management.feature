Feature: Review Management
  As a user
  I want to manage reviews
  So that I can organize my data

  Background:
    Given I am logged in as a user

  Scenario: Creating a new review
    When I go to the new review page
    And I fill in the form with valid data
    And I click "Create Review"
    Then I should see "Review created successfully"

  Scenario: Viewing a review
    Given a review exists
    When I go to the review page
    Then I should see the review details

  Scenario: Editing a review
    Given a review exists
    When I go to the edit review page
    And I update the form
    And I click "Update Review"
    Then I should see "Review updated successfully"

  Scenario: Deleting a review
    Given a review exists
    When I go to the reviews page
    And I click "Delete"
    Then I should see "Review deleted successfully"
