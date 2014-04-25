class ChangeMoviesName < ActiveRecord::Migration
   def up
    change_table :movies do |t|
      t.change :trailer, :string
    end
  end
 
  def down
    change_table :movies do |t|
      t.change :trailer, :text
    end
  end  
end
