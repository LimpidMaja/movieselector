class UserToken < ActiveRecord::Migration
  def up
    add_column   :users, :access_token_fb, :string 
      
  end
  
   def down
    remove_column :users, :access_token_fb, :string
    end
end
