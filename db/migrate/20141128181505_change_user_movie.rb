class ChangeUserMovie < ActiveRecord::Migration
  def up
    add_column   :user_movies, :date_collected, :datetime
      
  end
  
  def down      
    remove_column :user_movies, :date_collected, :datetime
  end
end
