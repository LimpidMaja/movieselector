class CreateMovies < ActiveRecord::Migration
  def change
    create_table :movies do |t|
      t.string :imdb_id
      t.string :tmdb_id
      t.string :trakt_id
      t.string :title
      t.integer :year
      t.string :poster
      t.float :imdb_rating
      t.integer :imdb_num_votes
      t.text :plot
      t.integer :runtime
      t.text :tagline
      t.text :trailer

      t.timestamps
    end
    
    create_table :movies_countries do |t|
      t.belongs_to :movie
      t.belongs_to :country
    end
    
    create_table :movies_languages do |t|
      t.belongs_to :movie
      t.belongs_to :language
    end
    
    create_table :movies_genres do |t|
      t.belongs_to :movie
      t.belongs_to :genre
    end
    
    create_table :movies_keywords do |t|
      t.belongs_to :movie
      t.belongs_to :keyword
    end
    
     create_table :movies_directors do |t|
      t.belongs_to :movie
      t.belongs_to :director
    end
    
    create_table :movie_writers do |t|
      t.belongs_to :movie
      t.belongs_to :writer
      t.string :role
      t.timestamps
    end
    
    create_table :movie_actors do |t|
      t.belongs_to :movie
      t.belongs_to :actor
      t.string :role
      t.timestamps
    end
  end
end
