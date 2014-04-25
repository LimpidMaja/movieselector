class ChangeUser < ActiveRecord::Migration
  def up
    change_table :users do |t|
      t.references :setting
    end
  end
 
  def down
      remove_column :users, :setting_id, :integer
  end  
end
