class UpdateList2 < ActiveRecord::Migration
  def up
    remove_column :lists, :type, :string
    add_column   :lists, :list_type, :string 
      
  end
  
   def down
     add_column   :lists, :type, :string 
      
    remove_column :lists, :list_type, :string
    end
end
