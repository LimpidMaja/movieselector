class CreateLists < ActiveRecord::Migration
  def change
    create_table :lists do |t|
      t.integer :user_id
      t.string :name
      t.text :description
      t.string :type
      t.string :privacy
      t.boolean :allow_edit
      t.string :edit_privacy
      t.float :rating
      t.integer :votes_count

      t.timestamps
    end
    
    create_table :list_movies do |t|
      t.integer :list_id
      t.integer :movie_id
      t.integer :list_order

      t.timestamps
    end
  end
end
