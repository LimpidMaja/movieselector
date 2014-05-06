class UserToken2 < ActiveRecord::Migration
  def up
    add_column   :users, :access_token_fb_expires, :string 
      
  end
  
   def down
    remove_column :users, :access_token_fb_expires, :string
    end
end
