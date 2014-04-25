class ChangeUser2 < ActiveRecord::Migration
  def change
   remove_column :users, :setting_id, :integer
  end 
end
