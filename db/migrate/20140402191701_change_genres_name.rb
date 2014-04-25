class ChangeGenresName < ActiveRecord::Migration
  
  def up
    change_table :genres do |t|
      t.change :name, :string
    end
  end
 
  def down
    change_table :genres do |t|
      t.change :name, :text
    end
  end  
end
