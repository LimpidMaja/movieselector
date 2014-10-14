class ChangeAccessKeyGcm < ActiveRecord::Migration
  def up
    add_column :access_keys, :gcm_reg_id, :string
  end
  
  def down         
    
    remove_column :access_keys, :gcm_reg_id, :string
  end
end
