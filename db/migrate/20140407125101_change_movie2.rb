class ChangeMovie2 < ActiveRecord::Migration
  def up
    change_table :movies do |t|
      t.string :original_title
      t.string :budget
      t.string :revenue
      t.string :status
    end
  end
 
  def down
      remove_column :movies, :original_title, :string
      remove_column :movies, :budget, :string
      remove_column :movies, :revenue, :string
      remove_column :movies, :status, :string
  end 
end
