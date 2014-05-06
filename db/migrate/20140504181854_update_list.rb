class UpdateList < ActiveRecord::Migration
  def up
    add_column   :lists, :watchlist, :boolean 
      
  end
  
   def down
    remove_column :lists, :watchlist, :boolean
    end
end
