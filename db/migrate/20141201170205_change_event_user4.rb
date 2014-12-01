class ChangeEventUser4 < ActiveRecord::Migration
  def up
    add_column   :event_users, :status, :integer, default: 0 
      
  end
  
  def down      
    remove_column :event_users, :status, :integer, default: 0
  end
end
