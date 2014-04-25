class ChangeCountriesName < ActiveRecord::Migration
   def up
    change_table :countries do |t|
      t.change :name, :string
    end
  end
 
  def down
    change_table :countries do |t|
      t.change :name, :text
    end
  end  
end
