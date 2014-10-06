class UpdateShowtime < ActiveRecord::Migration
   def up
    add_column :showtimes, :datetime, :datetime
    remove_column :showtimes, :date, :date
    remove_column :showtimes, :time, :time
      
  end
  
  def down
    add_column :showtimes, :date, :date
    add_column :showtimes, :time, :time
    remove_column :showtimes, :datetime, :datetime
  end
end
