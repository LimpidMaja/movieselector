class EventUser < ActiveRecord::Base  
  belongs_to :user
  belongs_to :event
        
  has_many :event_user_votes
   
  enum status: { waiting_others: 0, confirm: 1, add_movies: 2, vote: 3, knockout_choose: 4, winner: 5, 
    finished: 6, declined: 7, failed: 8, start_without_all: 9, continue_without_all: 10 } 
  
  enum accept: { waiting: 0, accepted: 1, declined: 2 }   
end
