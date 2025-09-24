class CreatePlayers < ActiveRecord::Migration[7.1]
  def change
    create_table :players do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :status
      t.boolean :active

      t.timestamps
    end

    add_index :players, :created_at
  end
end
