class User < ActiveRecord::Base
  def to_param
    username
  end
  
  has_many :authorizations
  
  searchkick
  has_one :setting, autosave: :true
  has_one :access_key, autosave: :true
  has_many :authorizations
  has_many :user_movies
  has_many :movies, through: :user_movies
  validates_presence_of :name
  has_many :lists
  has_many :friends
  has_many :event_users
  has_many :events, through: :event_users
  
  attr_accessor :picture
  attr_accessor :watched
  attr_accessor :collected
  attr_accessor :fb_uid
  attr_accessor :event_accepted
 
 
  scope :username_starts_with, ->(regex_str) { where(" username LIKE ? OR username LIKE ?", regex_str, regex_str + "_%") }
  
  def self.create_with_omniauth(auth)    
    create! do |user|
      user.setting = Setting.new
      user.setting.private = false
      user.authorizations.build :provider => auth["provider"], :uid => auth["uid"]      
      if auth['info']
         user.name = auth['info']['name'] || ""
         username = user.name.parameterize('_')                  
         count = User.username_starts_with(username).count        
         if count != 0           
           username += "_"
           username += count.to_s
         end
         user.username = username                  
         user.email = auth['info']['email'] || ""
      end
    end
  end

  def add_provider(auth_hash)
    # Check if the provider already exists, so we don't add it twice
    unless authorizations.find_by_provider_and_uid(auth_hash["provider"], auth_hash["uid"])
      Authorization.create :user => self, :provider => auth_hash["provider"], :uid => auth_hash["uid"]
    end
  end
  
  def refresh_facebook_access_token    
    # Checks the saved expiry time against the current time    
    if self
      auth = Authorization.find_by_user_id_and_provider(self.id, "facebook")        
      if self && auth.access_token && auth.access_token_expires.to_i < Time.now.to_i 
        begin   
          # Get the new token
          new_token = facebook_oauth.exchange_access_token_info(auth.access_token)
          # Save the new token and its expiry over the old one
          auth.access_token = new_token['access_token']
          auth.access_token_expires = Time.now.to_i +  + new_token['expires'].to_i
          auth.save
        end
      end
    end
  end
  
  def facebook_oauth
    @facebook_oauth ||= Koala::Facebook::OAuth.new(Rails.application.secrets.omniauth_provider_key.to_s, Rails.application.secrets.omniauth_provider_secret.to_s)
  end
end
