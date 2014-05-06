class UpdateUserMovies2 < ActiveRecord::Migration
  def up
    add_column   :user_movies, :watchlist, :boolean 
      
  end
  
  def down
    remove_column :user_movies, :watchlist, :boolean
  end
end
