class ChangeEvents2 < ActiveRecord::Migration
  def up
    add_column   :events, :knockout_phase, :integer, default: 0 
      
  end
  
  def down      
    remove_column :events, :knockout_phase, :integer, default: 0
  end
end
