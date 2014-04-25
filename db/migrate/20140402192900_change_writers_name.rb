class ChangeWritersName < ActiveRecord::Migration
  def up
    change_table :writers do |t|
      t.change :name, :string
      t.change :lastname, :string
    end
  end
 
  def down
    change_table :writers do |t|
      t.change :name, :text
      t.change :lastname, :text
    end
  end  
end
