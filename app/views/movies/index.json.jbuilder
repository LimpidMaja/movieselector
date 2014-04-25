json.array!(@movies) do |movie|
  json.extract! movie, :id, :imdb_id, :tmdb_id, :trakt_id, :title, :year, :poster, :imdb_rating, :imdb_num_votes, :plot, :runtime, :tagline, :trailer
  json.url movie_url(movie, format: :json)
end
