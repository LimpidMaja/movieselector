class ChangeEvents < ActiveRecord::Migration
  def up   
    if column_exists? :events, :rating_phase 
      remove_column :events, :rating_phase, :string    
    end
    add_column   :events, :rating_phase, :integer, default: 0 
    
    if column_exists? :events, :rating_system 
      remove_column :events, :rating_system, :string    
    end
    add_column :events, :rating_system, :integer
    
    if column_exists? :events, :voting_range 
     remove_column :events, :voting_range, :string   
    end 
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
