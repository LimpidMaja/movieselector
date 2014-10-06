json.array!(@showtimes) do |showtime|
  json.extract! showtime, :id, :movie_id, :title, :original_title, :cinema, :datetime, :is_3d, :is_synchronized, :city, :country, :state
  json.url showtime_url(showtime, format: :json)
end
