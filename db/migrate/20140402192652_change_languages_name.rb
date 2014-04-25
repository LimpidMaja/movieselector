class ChangeLanguagesName < ActiveRecord::Migration
   def up
    change_table :languages do |t|
      t.change :name, :string
    end
  end
 
  def down
    change_table :languages do |t|
      t.change :name, :text
    end
  end  
end
