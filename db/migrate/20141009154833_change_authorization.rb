class ChangeAuthorization < ActiveRecord::Migration
  def up
    remove_column :users, :access_token_fb, :string
    remove_column :users, :access_token_fb_expires, :string
    
    add_column :authorizations, :access_token, :string
    add_column :authorizations, :access_token_expires, :string
    
    add_column :users, :api_token, :string
    add_column :users, :api_token_expires, :string
      
  end
  
  def down      
    add_column :users, :access_token_fb, :string
    add_column :users, :access_token_fb_expires, :string
    remove_column :authorizations, :access_token, :string
    remove_column :authorizations, :access_token_expires, :string
    
    remove_column :users, :api_token, :string
    remove_column :users, :api_token_expires, :string
    
  end
end
