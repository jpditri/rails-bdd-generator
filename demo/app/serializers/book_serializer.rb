class BookSerializer < ActiveModel::Serializer
  attributes :id, :title, :author, :isbn, :description, :price, :stock_quantity, :published_at, :category, :active, :created_at, :updated_at

  belongs_to :user
end
