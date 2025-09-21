class Book < ApplicationRecord
  has_many :reviews
  has_many :order_items
  validates :title, presence: true
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Book ##{id}"
  end
end
