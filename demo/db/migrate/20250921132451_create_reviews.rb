class CreateReviews < ActiveRecord::Migration[7.1]
  def change
    create_table :reviews do |t|
      t.integer :rating
      t.string :title
      t.text :content
      t.boolean :verified_purchase

      t.timestamps
    end

    add_index :reviews, :created_at
  end
end
