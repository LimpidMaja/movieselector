class Event < ActiveRecord::Base
    
  has_many :event_movies
  has_many :movies, through: :event_movies
    
  has_many :event_users
  has_many :users, through: :event_users
  
end
