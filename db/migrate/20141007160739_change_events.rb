class ChangeEvents < ActiveRecord::Migration
  def up    
    remove_column :events, :rating_phase, :string    
    add_column   :events, :rating_phase, :integer, default: 0 
    
    remove_column :events, :rating_system, :string    
    add_column :events, :rating_system, :integer
    
    remove_column :events, :voting_range, :string    
    add_column :events, :voting_range, :integer
    
  end
  
  def down      
    remove_column :events, :rating_phase, :integer
    remove_column :events, :rating_system, :integer
    remove_column :events, :voting_range, :integer
    add_column :events, :rating_phase, :string
    add_column :events, :rating_system, :string
    add_column :events, :voting_range, :string
  end
end
