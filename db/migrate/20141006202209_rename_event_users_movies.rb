class RenameEventUsersMovies < ActiveRecord::Migration
  def change
    def self.up
    rename_table :events_users, :event_users
    rename_table :events_movies, :event_movies
  end

 def self.down
    rename_table :event_movies, :events_movies
    rename_table :event_users, :events_users
 end
  end
end
