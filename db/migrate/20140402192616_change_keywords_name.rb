class ChangeKeywordsName < ActiveRecord::Migration
  def up
    change_table :keywords do |t|
      t.change :name, :string
    end
  end
 
  def down
    change_table :keywords do |t|
      t.change :name, :text
    end
  end  
end
