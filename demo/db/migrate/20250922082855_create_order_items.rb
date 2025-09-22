class CreateOrderItems < ActiveRecord::Migration[7.1]
  def change
    create_table :order_items do |t|
      t.integer :quantity
      t.decimal :unit_price
      t.decimal :subtotal

      t.timestamps
    end

    add_index :order_items, :created_at
  end
end
