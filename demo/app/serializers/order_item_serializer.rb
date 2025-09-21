class Order_itemSerializer < ActiveModel::Serializer
  attributes :id, :quantity, :unit_price, :subtotal, :created_at, :updated_at

  belongs_to :user
end
