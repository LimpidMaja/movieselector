class MovieWriter < ActiveRecord::Base  
  belongs_to :movie
  belongs_to :writer
end
