class Friend < ActiveRecord::Base
  belongs_to :movie
  
  
  attr_accessor :picture
  attr_accessor :name
  attr_accessor :friend_user_id
  attr_accessor :username
end
