class Author < ApplicationRecord
  
  
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "Author ##{id}"
  end
end
