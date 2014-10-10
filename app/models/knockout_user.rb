class KnockoutUser < ActiveRecord::Base    
  belongs_to :event_knockout 
  belongs_to :user
end
