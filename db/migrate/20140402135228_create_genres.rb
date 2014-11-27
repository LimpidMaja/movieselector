class CreateGenres < ActiveRecord::Migration
  unless table_exists? :genres
    def change
      create_table :genres do |t|
        t.text :name, :limit=>255
  
        t.timestamps
      end
      add_index :genres, :name, unique: true, :length => { :name => 255 }
    end
  end
end
