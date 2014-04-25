class ChangeMovieMissing < ActiveRecord::Migration
  def up
    change_table :movies do |t|
      t.boolean :missing_data
    end
  end

  def down
    remove_column :movies, :missing_data, :boolean
  end
end
