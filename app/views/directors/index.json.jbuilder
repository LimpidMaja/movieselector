json.array!(@directors) do |director|
  json.extract! director, :id, :name
  json.url director_url(director, format: :json)
end
