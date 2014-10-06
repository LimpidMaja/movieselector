json.array!(@friends) do |friend|
  json.extract! friend, :id, :user_id, :friend_id, :facebook_id, :friend_confirm
  json.url friend_url(friend, format: :json)
end
