class Order < ApplicationRecord
  has_many :order_items
  
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Order ##{id}"
  end
end
