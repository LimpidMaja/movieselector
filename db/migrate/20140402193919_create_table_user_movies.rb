class CreateTableUserMovies < ActiveRecord::Migration
  def change
    create_table :user_movies do |t|
      t.belongs_to :user
      t.belongs_to :movie
      t.boolean :watched
      t.datetime :date_watched
      t.boolean :collection
      t.timestamps
    end
  end
end
