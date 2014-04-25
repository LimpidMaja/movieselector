class Actor < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged

  searchkick word_start: [:name], suggest: ["name"]
  
  has_many :movie_actors
  has_many :movies, through: :movie_actors
end
