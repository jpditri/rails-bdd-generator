class CreateBooks < ActiveRecord::Migration[7.1]
  def change
    create_table :Books do |t|
      t.string :title
      t.text :description
      t.string :isbn
      t.date :publication_date
      t.decimal :price
      t.integer :stock_quantity

      t.timestamps
    end

    add_index :Books, :created_at
  end
end
