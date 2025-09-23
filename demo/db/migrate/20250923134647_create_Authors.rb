class CreateAuthors < ActiveRecord::Migration[7.1]
  def change
    create_table :Authors do |t|
      t.string :first_name
      t.string :last_name
      t.text :bio

      t.timestamps
    end

    add_index :Authors, :created_at
  end
end
