json.array!(@writers) do |writer|
  json.extract! writer, :id, :name
  json.url writer_url(writer, format: :json)
end
