class Review < ApplicationRecord
  belongs_to :books
  belongs_to :users
  validates :title, presence: true
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Review ##{id}"
  end
end
