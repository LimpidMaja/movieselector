class ChangeMovie < ActiveRecord::Migration
  def up
    change_table :movies do |t|
      t.string :fanart
      t.string :rated
      t.string :released
    end
  end
 
  def down
      remove_column :movies, :fanart, :string
      remove_column :movies, :rated, :string
      remove_column :movies, :released, :string
  end 
end
