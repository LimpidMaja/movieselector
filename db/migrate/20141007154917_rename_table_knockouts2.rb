class RenameTableKnockouts2 < ActiveRecord::Migration
   def up
    rename_table :events_movies_knockout, :event_knockouts
  end
  
  def down
    rename_table :event_knockouts, :events_movies_knockout
  end
end
