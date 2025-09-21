class ReviewSerializer < ActiveModel::Serializer
  attributes :id, :rating, :title, :content, :verified_purchase, :created_at, :updated_at

  belongs_to :user
end
