class RenameEventUsersMovies2 < ActiveRecord::Migration
  def up
    rename_table :events_users, :event_users
    rename_table :events_movies, :event_movies
  end
  
  def down
    rename_table :event_movies, :events_movies
    rename_table :event_users, :events_users
  end
end
