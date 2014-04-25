class CreateGenres < ActiveRecord::Migration
  def change
    create_table :genres do |t|
      t.text :name

      t.timestamps
    end
    add_index :genres, :name, unique: true
  end
end
