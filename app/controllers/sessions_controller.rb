class SessionsController < ApplicationController

  def new
    redirect_to '/auth/facebook'
  end

  def create
    logger.info "\n CREATE USER!!!!!!\n" 
    auth = request.env["omniauth.auth"]
    user = User.where(:provider => auth['provider'],
                      :uid => auth['uid'].to_s).first || User.create_with_omniauth(auth)
                 
    logger.info "\nTOKEN: " + auth['credentials']['token'].to_s + "\n"
    if user.access_token_fb != auth['credentials']['token']
      user.access_token_fb = auth['credentials']['token']
      user.access_token_fb_expires = auth['credentials']['expires_at']
      user.save    
    end
    
    Thread.new do
      Movie.sync_facebook(user) 
    end
    # Reset the session after successful login, per
    # 2.8 Session Fixation – Countermeasures:
    # http://guides.rubyonrails.org/security.html#session-fixation-countermeasures
    
    reset_session
    session[:user_id] = user.username
    if user.email.blank?
      redirect_to edit_user_path(user), :alert => "Please enter your email address."
    else
      redirect_to root_url, :notice => 'Signed in!'
    end

  end
  
  def update
    logger.info "\n CREATE USER!!!!!!\n" 
    auth = request.env["omniauth.auth"]
  end

  def destroy
    reset_session
    redirect_to root_url, :notice => 'Signed out!'
  end

  def failure
    redirect_to root_url, :alert => "Authentication error: #{params[:message].humanize}"
  end

end
