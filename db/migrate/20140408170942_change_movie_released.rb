class ChangeMovieReleased < ActiveRecord::Migration
  def up
    change_table :movies do |t|
      t.date :release_date
    end
    remove_column :movies, :released, :string
  end

  def down
    remove_column :movies, :release_date, :date
    change_table :movies do |t|
      t.string :released
    end
  end
end
