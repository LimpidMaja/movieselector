class Api::V1::SessionsController < ApplicationController
  protect_from_forgery with: :null_session, :if => Proc.new { |c| c.request.format == 'application/vnd.myapp.v1' }

  def create
    print "SESSION CREATE \n"
    if params[:provider] == "facebook"
      begin
        @graph = Koala::Facebook::API.new(params[:access_token])
        if !@graph.nil?
          user_result = @graph.get_connections("me?fields=id,email,name&access_token=" + params[:access_token], "")
          
          if params[:uid] == user_result.id         
            @oauth = Koala::Facebook::OAuth.new(Rails.application.secrets.omniauth_provider_key.to_s, Rails.application.secrets.omniauth_provider_secret.to_s)
            app_token = @oauth.get_app_access_token          
            verification_result = @graph.get_connections("debug_token?input_token=" + app_token + "&access_token=" + params[:access_token], "")
            is_valid = verification_result.data.is_valid
            if is_valid == true
              print "IS VALID!!!"
              
              @authorization = Authorization.find_by_provider_and_uid(params[:provider], params[:uid])
              if @authorization
                @user = @authorization.user
                print "ALREADY USER"
                #render :text => "Welcome back #{@authorization.user.name}! You have already signed up."
              else   
                if user_result['email']                  
                  @user = User.find_by_email(user_result['email'])
                else
                  @user = User.find_by_email(params[:email])
                end
                                  
                auth = {}
                auth['uid'] = params[:uid]
                auth['provider'] = params[:provider]
                info = {}
                info['name'] = user_result.name
                info['email'] = user_result.email
                auth['info'] = info
                
                print "AUTH: " + auth.to_yaml
                if @user
                  print "NEW PROVIDER USER"
                  @user.add_provider(auth)
                  @authorization = Authorization.find_by_provider_and_uid(params[:provider], params[:uid])
                else
                  print "NEW USER"
                  @user = User.create_with_omniauth(auth)
                  @authorization = Authorization.find_by_provider_and_uid(params[:provider], params[:uid])
                end   
              end
        
              if @authorization.access_token != params[:access_token]
                @authorization.access_token = params[:access_token]
                print "EXPIRES: " + params[:expires_at]
                @authorization.access_token_expires = params[:expires_at]
                @authorization.save    
              end
              
              #Thread.new do
              #  Movie.sync_facebook(@user) 
              #end

              if @user.access_key.nil?
                p "NEW ACCESS KEY"
                @access_key = AccessKey.new
                @access_key.user_id = @user.id
                @access_key.access_token_expires = 2.month.from_now.to_i
                @access_key.save
                p "ACCESS KEY" + access_key.to_yaml
              elsif @user.access_key.access_token_expires.to_i < Time.now.to_i 
                p "ACCESS KEY EXPIRED"
                @user.access_key.destroy
                @access_key = AccessKey.new
                @access_key.user_id = @user.id
                @access_key.access_token_expires = 2.month.from_now.to_i
                @access_key.save
              else
                @access_key = @user.access_key
              end
              
              render :json => { :info => "Logged in", :access_token => @access_key.access_token }, :status => 200
            else 
              print "NOT VALID"
              render :json => { :info => "Error" }, :status => 403
            end
          end
        end
      rescue Koala::Facebook::AuthenticationError
        print "ACCESS TOKEN NOT VALID"
        render :json => { :info => "Error" }, :status => 403
      #rescue Exception
       # print "UNKNOWN ERROR"
       # render :json => { :info => "Error" }, :status => 403
      end
    end
   
    
=begin      
    if user.email.blank?
      redirect_to edit_user_path(user), :alert => "Please enter your email address."
    else
      redirect_to root_url, :notice => 'Signed in!'
    end
=end    
   
  end
  

  def destroy
    #warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#failure")
    #sign_out
    #render :json => { :info => "Logged out" }, :status => 200
  end
end
