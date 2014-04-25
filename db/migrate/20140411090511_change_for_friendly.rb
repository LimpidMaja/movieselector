class ChangeForFriendly < ActiveRecord::Migration
  def up
    add_column   :companies, :slug, :string, unique: true    
  end

  def down
    remove_column :companies, :slug, :string
  end
end
