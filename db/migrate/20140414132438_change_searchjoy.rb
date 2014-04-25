class ChangeSearchjoy < ActiveRecord::Migration
  def up
    add_column   :searchjoy_searches, :user_id, :integer 
      
  end
  
   def down
    remove_column :searchjoy_searches, :user_id, :integer
    end
end
