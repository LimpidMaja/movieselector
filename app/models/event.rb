class Event < ActiveRecord::Base
  enum rating_system: { voting: 0, knockout: 1, tags: 2, random: 3 }
  enum rating_phase: { starting: 0, knockout_match: 1 }  
  enum voting_range: { one_to_five: 0, one_to_ten: 1, up_down: 2 }    
  
  has_many :event_movies
  has_many :movies, through: :event_movies
    
  has_many :event_users
  has_many :users, through: :event_users
  
end
