Feature: User Management
  As a user
  I want to manage users
  So that I can organize my data

  Background:
    Given I am logged in as a user

  Scenario: Creating a new user
    When I go to the new user page
    And I fill in the form with valid data
    And I click "Create User"
    Then I should see "User created successfully"

  Scenario: Viewing a user
    Given a user exists
    When I go to the user page
    Then I should see the user details

  Scenario: Editing a user
    Given a user exists
    When I go to the edit user page
    And I update the form
    And I click "Update User"
    Then I should see "User updated successfully"

  Scenario: Deleting a user
    Given a user exists
    When I go to the users page
    And I click "Delete"
    Then I should see "User deleted successfully"
