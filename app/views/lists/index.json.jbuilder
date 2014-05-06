json.array!(@lists) do |list|
  json.extract! list, :id, :name, :description, :list_type, :privacy, :allow_edit, :rating, :votes_count, :user_id
  json.url list_url(list, format: :json)
end
