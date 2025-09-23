class Book < ApplicationRecord
  has_and_belongs_to_many :Authors
  belongs_to :Categories
  validates :title, presence: true
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Book ##{id}"
  end
end
