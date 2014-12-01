class UserMovie < ActiveRecord::Base  
  belongs_to :movie
  belongs_to :user
  
end
