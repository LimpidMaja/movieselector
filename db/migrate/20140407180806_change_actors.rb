class ChangeActors < ActiveRecord::Migration
  def up
    change_table :actors do |t|
      t.string :image
    end

    remove_column :actors, :lastname, :string
  end

  def down
    remove_column :actors, :image, :string
    change_table :actors do |t|
      t.string :lastname
    end
  end
end
