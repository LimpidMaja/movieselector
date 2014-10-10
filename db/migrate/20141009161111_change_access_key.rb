class ChangeAccessKey < ActiveRecord::Migration
  def up
    remove_column :users, :api_token, :string
    remove_column :users, :api_token_expires, :string
    remove_column :users, :provider, :string
    remove_column :users, :uid, :string
            
    add_column :access_keys, :user_id, :integer
    add_column :access_keys, :access_token_expires, :string
      
  end
  
  def down         
    
    add_column :users, :api_token, :string
    add_column :users, :api_token_expires, :string
    add_column :users, :provider, :string
    add_column :users, :uid, :string
    
    remove_column :access_keys, :user_id, :integer
    remove_column :access_keys, :access_token_expires, :string
  end
end
