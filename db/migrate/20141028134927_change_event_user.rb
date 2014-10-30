class ChangeEventUser < ActiveRecord::Migration
  def up
    add_column   :event_users, :accept, :integer, default: 0 
      
  end
  
  def down      
    remove_column :event_users, :accept, :integer, default: 0
  end
end
