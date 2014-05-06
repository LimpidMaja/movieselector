class List < ActiveRecord::Base
  has_many :list_movies
  has_many :movies, through: :list_movies
end
