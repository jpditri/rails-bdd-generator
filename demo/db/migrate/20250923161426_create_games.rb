class CreateGames < ActiveRecord::Migration[7.1]
  def change
    create_table :games do |t|
      t.string :name
      t.text :description
      t.decimal :price
      t.string :status
      t.boolean :active

      t.timestamps
    end

    add_index :games, :created_at
  end
end
