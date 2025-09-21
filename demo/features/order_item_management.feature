Feature: Order_item Management
  As a user
  I want to manage order_items
  So that I can organize my data

  Background:
    Given I am logged in as a user

  Scenario: Creating a new order_item
    When I go to the new order_item page
    And I fill in the form with valid data
    And I click "Create Order_item"
    Then I should see "Order_item created successfully"

  Scenario: Viewing a order_item
    Given a order_item exists
    When I go to the order_item page
    Then I should see the order_item details

  Scenario: Editing a order_item
    Given a order_item exists
    When I go to the edit order_item page
    And I update the form
    And I click "Update Order_item"
    Then I should see "Order_item updated successfully"

  Scenario: Deleting a order_item
    Given a order_item exists
    When I go to the order_items page
    And I click "Delete"
    Then I should see "Order_item deleted successfully"
