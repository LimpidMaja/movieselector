class Movie < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_and_belongs_to_many :genres, :join_table => :movies_genres
  has_and_belongs_to_many :keywords, :join_table => :movies_keywords
  has_and_belongs_to_many :languages, :join_table => :movies_languages
  has_and_belongs_to_many :countries, :join_table => :movies_countries
  has_and_belongs_to_many :directors, :join_table => :movies_directors
  has_and_belongs_to_many :companies, :join_table => :movies_companies
  has_many :movie_writers
  has_many :writers, through: :movie_writers
  has_many :movie_actors
  has_many :actors, through: :movie_actors
  has_many :user_movies
  has_many :users, through: :user_movies
  
  searchkick word_start: [:title, :original_title], suggest: [:title, :actors_name, :original_title, :directors_name, :writers_name, :companies_name, :genres_name, :countries_name]

  def search_data
    {
      title: title,
      imdb_id: imdb_id,
      tmdb_id: tmdb_id,
      original_title: original_title,
      imdb_rating: imdb_rating,
      plot: plot,
      tagline: tagline,
      year: year,
      runtime: runtime,
      actors_name: actors.map(&:name),
      directors_name: directors.map(&:name),
      writers_name: writers.map(&:name),
      companies_name: companies.map(&:name),
      genres_name: genres.map(&:name),
      countries_name: countries.map(&:name),
      languages_name: languages.map(&:name),
      keywords_name: keywords.map(&:name)
    }
  end
  
  
end
