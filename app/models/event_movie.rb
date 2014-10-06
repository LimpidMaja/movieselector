class EventMovie < ActiveRecord::Base  
  belongs_to :movie
  belongs_to :event
end
