class ChangeEventUser3 < ActiveRecord::Migration
   def up
    remove_column :event_users, :accept, :boolean, default: false    
    add_column   :event_users, :accept, :integer, default: 0  
      
  end
  
  def down      
    remove_column :event_users, :accept, :integer, default: 0
    add_column   :event_users, :accept, :boolean, default: false  
       
  end
end
