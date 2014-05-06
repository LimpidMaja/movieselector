class User < ActiveRecord::Base
  def to_param
    username
  end
  searchkick
  has_one :setting, autosave: :true
  has_many :user_movies
  has_many :movies, through: :user_movies
  validates_presence_of :name
  has_many :lists
 
  scope :username_starts_with, ->(regex_str) { where(" username LIKE ? OR username LIKE ?", regex_str, regex_str + "_%") }
  
  def self.create_with_omniauth(auth)
    create! do |user|
      user.provider = auth['provider']
      user.uid = auth['uid']
      user.access_token_fb = auth['credentials']['token']
      user.access_token_fb_expires = auth['credentials']['expires_at']
      user.setting = Setting.new
      user.setting.private = false
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

end
