class ChangeEvents < ActiveRecord::Migration
  def up
    change_column :events, :rating_system, :integer, default: 0 
    change_column :events, :voting_range, :integer, default: 0 
    add_column   :events, :rating_phase, :integer, default: 0 
      
  end
  
  def down      
    remove_column :events, :rating_phase, :integer, default: 0
    change_column :events, :rating_system, :string
    change_column :events, :voting_range, :string
  end
end
