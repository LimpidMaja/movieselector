class SessionsController < ApplicationController

  def new
    redirect_to '/auth/facebook'
  end

  def create
    logger.info "\n CREATE USER!!!!!!\n" 
    User.delete_all
    Authorization.delete_all
    AccessKey.delete_all
    p "USERS: " + User.all.to_yaml
    p "AUTH: " + Authorization.all.to_yaml
    auth = request.env["omniauth.auth"]
    if session[:user_id]
      # Means our user is signed in. Add the authorization to the user
      @user = User.find(session[:user_id])
      @user.add_provider(auth)
      @authorization = Authorization.find_by_provider_and_uid(auth["provider"], auth["uid"])
      #render :text => "You can now login using #{auth_hash["provider"].capitalize} too!"
    else       
      @authorization = Authorization.find_by_provider_and_uid(auth["provider"], auth["uid"])
      if @authorization
        @user = @authorization.user
        #render :text => "Welcome back #{@authorization.user.name}! You have already signed up."
      else
        @user = User.find_by_email(auth["info"]["email"])
        if @user
          @user.add_provider(auth)
        else
          @user = User.create_with_omniauth(auth)
        end   
        @authorization = Authorization.find_by_provider_and_uid(auth["provider"], auth["uid"])
        #render :text => "Hi #{user.name}! You've signed up."
      end
    end
    
    # Reset the session after successful login, per
    # 2.8 Session Fixation – Countermeasures:
    # http://guides.rubyonrails.org/security.html#session-fixation-countermeasures
    reset_session 
    session[:user_id] = @user.username
       
    if auth["provider"] == "facebook"
      if @authorization.access_token != auth['credentials']['token']
        @authorization.access_token = auth['credentials']['token']
        @authorization.access_token_expires = auth['credentials']['expires_at']
        @authorization.save    
      end
      
      Thread.new do
        Movie.sync_facebook(@user) 
      end
    end
       
    if @user.email.blank?
      redirect_to edit_user_path(@user), :alert => "Please enter your email address."
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
