class CreateCategories < ActiveRecord::Migration[7.1]
  def change
    create_table :Categories do |t|
      t.string :name
      t.text :description

      t.timestamps
    end

    add_index :Categories, :created_at
  end
end
