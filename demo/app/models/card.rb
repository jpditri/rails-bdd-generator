class Card < ApplicationRecord
  
  validates :name, presence: true
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Card ##{id}"
  end
end
