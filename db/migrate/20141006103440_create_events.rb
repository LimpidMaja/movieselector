class CreateEvents < ActiveRecord::Migration 
   
    
  def change
       
    create_table :events do |t|
      t.string :name
      t.text :description
      t.date :event_date
      t.time :event_time
      t.string :place
      t.integer :time_limit
      t.integer :minimum_voting_percent
      t.references :user
      t.boolean :finished
      t.boolean :users_can_add_movies
      t.integer :num_add_movies_by_user
      t.string :rating_system
      t.integer :num_votes_per_user
      t.string :voting_range
      t.boolean :tie_knockout
      t.integer :knockout_rounds
      t.integer :knockout_time_limit
      t.boolean :wait_time_limit
      
      t.timestamps
    end
    
     create_table :events_users do |t|
      t.belongs_to :user
      t.belongs_to :event
      t.integer :num_votes
    end
    
    create_table :events_movies do |t|
      t.belongs_to :movie
      t.belongs_to :event
      t.integer :num_votes
      t.float :score     
      t.boolean :out 
    end
    
    create_table :events_movies_knockout do |t|
      t.integer :movie_id_1
      t.integer :movie_id_2
      t.integer :movie_1_score
      t.integer :movie_2_score
      t.references :event 
      t.integer :num_votes
      
    end
  end
end
