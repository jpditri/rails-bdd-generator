class User < ApplicationRecord
  has_many :cards
  has_many :decks
  has_many :players
  has_many :games
  validates :email, presence: true
  validates :email, uniqueness: true, format: { with: URI::MailTo::EMAIL_REGEXP }
  scope :active, -> { where(active: true) }
scope :recent, -> { order(created_at: :desc) }

  def display_name
    respond_to?(:name) ? name : "User ##{id}"
  end
end
