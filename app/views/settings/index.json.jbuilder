json.array!(@settings) do |setting|
  json.extract! setting, :id, :private, :trakt_username, :trakt_password
  json.url user_setting_url(setting, format: :json)
end
