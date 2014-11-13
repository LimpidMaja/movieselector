class Event < ActiveRecord::Base
  enum rating_system: { voting: 0, knockout: 1, tags: 2, random: 3 }
  enum rating_phase: { wait_users: 0, starting: 1, knockout_match: 2, done: 3 }  
  enum voting_range: { one_to_five: 0, one_to_ten: 1, up_down: 2 }   
  enum event_status: { waiting_others: 0, confirm: 1, add_movies: 2, vote: 3, knockout_choose: 4, winner: 5, finished: 6, declined: 7, failed: 8, start_without_all: 9 } 
  
  has_many :event_movies
  has_many :movies, through: :event_movies
    
  has_many :event_users
  has_many :users, through: :event_users
  
  attr_accessor :friends
  attr_accessor :event_status
  attr_accessor :winner_movie
  attr_accessor :knockout_matches
end
