class RenameTableKnockouts < ActiveRecord::Migration
    def up
    rename_table :events_movies_knockout, :event_knockouts
  end
  
  def down
    rename_table :event_knockouts, :events_movies_knockout
  end
  
  def change
       
    create_table :knockout_users do |t|
      t.belongs_to :user
      t.belongs_to :event_knockout
      t.integer :num_votes      
    end
  end
end
