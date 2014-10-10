class ChangeEventKnockouts < ActiveRecord::Migration
  def up
    add_column   :event_knockouts, :round, :integer, default: 1 
    add_column   :event_knockouts, :winner, :boolean, default: false 
      
  end
  
  def down      
    remove_column :event_knockouts, :round, :integer
    remove_column :event_knockouts, :winner, :boolean
  end
end
