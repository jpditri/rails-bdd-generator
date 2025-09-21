class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.string :order_number
      t.decimal :total_amount
      t.string :status
      t.text :shipping_address
      t.string :payment_method
      t.text :notes
      t.datetime :shipped_at

      t.timestamps
    end

    add_index :orders, :created_at
  end
end
