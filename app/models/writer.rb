class Writer < ActiveRecord::Base
  extend FriendlyId
  friendly_id :name, use: :slugged
  searchkick word_start: [:name], suggest: ["name"]
  has_many :movie_writers
  has_many :movies, through: :movie_writers
end
