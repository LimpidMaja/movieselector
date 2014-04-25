class ChangeMovieAwards < ActiveRecord::Migration
  def up
    change_table :movies do |t|
      t.string :awards
    end
  end

  def down
    remove_column :movies, :awards, :string
  end
end
