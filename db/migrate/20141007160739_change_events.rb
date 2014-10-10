class ChangeEvents < ActiveRecord::Migration
  def up
    change_column :events, :rating_system, :integer 
    change_column :events, :voting_range, :integer 
    add_column   :events, :rating_phase, :integer, default: 0 
      
  end
  
  def down      
    remove_column :events, :rating_phase, :integer
    change_column :events, :rating_system, :string
    change_column :events, :voting_range, :string
  end
end
