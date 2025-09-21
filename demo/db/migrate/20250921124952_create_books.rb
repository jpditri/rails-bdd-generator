class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :books do |t|
      t.string :title
      t.string :author
      t.string :isbn
      t.text :description
      t.decimal :price
      t.integer :stock_quantity
      t.date :published_at
      t.string :category
      t.boolean :active

      t.timestamps
    end

    add_index :books, :created_at
  end
end
