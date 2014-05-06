Rails.application.config.middleware.use OmniAuth::Builder do
  provider :facebook, Rails.application.secrets.omniauth_provider_key, Rails.application.secrets.omniauth_provider_secret,
           :scope => 'email,public_profile,user_friends,user_hometown,user_location,read_friendlists,user_actions.video', :display => 'popup'
end
