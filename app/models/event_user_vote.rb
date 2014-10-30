class EventUserVote < ActiveRecord::Base  
  belongs_to :user
  belongs_to :event
  belongs_to :movie
     
end
