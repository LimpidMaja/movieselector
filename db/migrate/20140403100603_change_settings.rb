class ChangeSettings < ActiveRecord::Migration
  def up
    change_table :settings do |t|
      t.references :user
    end
  end
 
  def down
      remove_column :settings, :user_id, :integer
  end 
end
