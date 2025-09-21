class OrderSerializer < ActiveModel::Serializer
  attributes :id, :order_number, :total_amount, :status, :shipping_address, :payment_method, :notes, :shipped_at, :created_at, :updated_at

  belongs_to :user
end
