class CreateCards < ActiveRecord::Migration[7.1]
  def change
    create_table :cards do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :status
      t.boolean :active

      t.timestamps
    end

    add_index :cards, :created_at
  end
end
