class ChangeDirectorsAndWriters < ActiveRecord::Migration
  def up
    change_table :directors do |t|
      t.string :image
    end

    remove_column :directors, :lastname, :string
    
    change_table :writers do |t|
      t.string :image
    end

    remove_column :writers, :lastname, :string
  end

  def down
    remove_column :directors, :image, :string
    change_table :directors do |t|
      t.string :lastname
    end
    
    remove_column :writers, :image, :string
    change_table :writers do |t|
      t.string :lastname
    end
  end
end
