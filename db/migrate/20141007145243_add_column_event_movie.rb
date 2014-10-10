class AddColumnEventMovie < ActiveRecord::Migration
  def up
    add_column   :event_movies, :winner, :boolean
  end
  
  def down
    remove_column :event_movies, :winner, :boolean
  end
end
