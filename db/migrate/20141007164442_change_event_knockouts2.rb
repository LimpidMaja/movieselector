class ChangeEventKnockouts2 < ActiveRecord::Migration
  def up
    remove_column :event_knockouts, :winner, :boolean
    add_column   :event_knockouts, :finished, :boolean, default: 0 
      
  end
  
  def down      
    remove_column :event_knockouts, :finished, :boolean
    add_column   :event_knockouts, :winner, :boolean, default: false 
  end
end
