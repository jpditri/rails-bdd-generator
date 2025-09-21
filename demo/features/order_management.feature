Feature: Order Management
  As a user
  I want to manage orders
  So that I can organize my data

  Background:
    Given I am logged in as a user

  Scenario: Creating a new order
    When I go to the new order page
    And I fill in the form with valid data
    And I click "Create Order"
    Then I should see "Order created successfully"

  Scenario: Viewing a order
    Given a order exists
    When I go to the order page
    Then I should see the order details

  Scenario: Editing a order
    Given a order exists
    When I go to the edit order page
    And I update the form
    And I click "Update Order"
    Then I should see "Order updated successfully"

  Scenario: Deleting a order
    Given a order exists
    When I go to the orders page
    And I click "Delete"
    Then I should see "Order deleted successfully"
