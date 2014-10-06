json.array!(@events) do |event|
  json.extract! event, :id, :name, :description, :event_date, :event_time, :place, :time_limit, :minimum_voting_percent
  json.url event_url(event, format: :json)
end
