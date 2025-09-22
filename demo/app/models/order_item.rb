class Order_item < ApplicationRecord
  belongs_to :books
  belongs_to :orders
  
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Order_item ##{id}"
  end
end
