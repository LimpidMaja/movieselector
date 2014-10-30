class EventUser < ActiveRecord::Base  
  belongs_to :user
  belongs_to :event
        
  has_many :event_user_votes
  
  enum accept: { waiting: 0, accepted: 1, declined: 2 }   
end
