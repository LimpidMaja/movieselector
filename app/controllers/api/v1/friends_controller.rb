class Api::V1::FriendsController < ApplicationController
  before_filter :restrict_access  
  respond_to :json
  
  require 'gcm'  
  include ActionController::HttpAuthentication::Token
    
 def autocomplete    
    print "TEST events" 
    render json: Movie.search(params[:query], fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:title)
  end
  
  # GET /friends
  # GET /friends.json
  def index
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
 
=begin            
      @users = User.where('id not in (?)',@user.id)
      list = @users.map do |friend_user|
        if @user.id != friend_user.id
          p "USER: " + friend_user.name + "\n"
         auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
         { :id => friend_user.id,
           :name => friend_user.name,
           :username => friend_user.username,
           :facebookUID => auth.uid,
           :confirmed => false,
           :request => false
         }
         end
      end
=end      
              
      @friends = @user.friends
            
      list_friends = @friends.map do |friend|
         if friend.friend_confirm == true
           friend_user = User.find_by_id(friend.friend_id)
           auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
           { :id => friend_user.id,
             :name => friend_user.name,
             :username => friend_user.username,
             :facebookUID => auth.uid,
             :confirmed => true,
             :request => false
           }
        end
      end
      
      list = list_friends          
      
      @friend_requests = Friend.where(:friend_id => @user.id, :friend_confirm => false)
      list_request = @friend_requests.map do |friend|
        friend_user = User.find_by_id(friend.user_id)
         auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
         { :id => friend_user.id,
           :name => friend_user.name,
           :username => friend_user.username,
           :facebookUID => auth.uid,
           :confirmed => false,
           :request => true
         }           
      end
    
      list = list + list_request                
      
      auth = Authorization.find_by_user_id_and_provider(@user.id, "facebook")        
      @graph = Koala::Facebook::API.new(auth.access_token, Rails.application.secrets.omniauth_provider_secret.to_s)
      
      @friends_fb = []      
      if !@graph.nil?
        begin
          friends_fb = @graph.get_connections("me", "friends")
          begin        
           #logger.info "\n @next_page " + videos.to_yaml
           if !friends_fb.nil?     
              #logger.info "\n FRIENDS: " + friends_fb.to_yaml       
              count = friends_fb.count
              friends_fb.each do |friend|    
                if !friend.nil?
                  auth = Authorization.find_by_uid(friend.id)                
                  if auth
                    logger.info "\n FRIEND: " + friend.name.to_yaml 
                    if !list.map(&:id).include? auth.user.id
                      logger.info "\n FRIEND add: " + friend.name.to_yaml 
                      @friends_fb << auth.user
                    end
                  end             
                end 
              end               
            end         
          end while friends_fb = friends_fb.next_page                
        rescue => e
          logger.error "\n FACEBOOK FRIENDS RESULT ERROR: " + e.to_s + "\n"
        end
      end
      p "MY FB FRIENDS: " +  @friends_fb.to_yaml
      
      list_fb = @friends_fb.map do |friend_user|
         auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
         { :id => friend_user.id,
           :name => friend_user.name,
           :username => friend_user.username,
           :facebookUID => auth.uid,
           :confirmed => false,
           :request => false
         }
      end
                       
      list = list + list_fb   
                            
      list = list.compact         
      list.to_json
      respond_with :friends => list
      
    else
      render :friends => { :info => "Error" }, :status => 403
    end           
  end
  
  def send_friend_request
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      puts "FOLLOW"
      if params[:id].present?  
        friend_user = User.find(params[:id])
        puts "FRIEND USER: " + friend_user.to_yaml
        if friend_user && friend_user.id != @user.id
          friend = Friend.find_by_user_id_and_friend_id(@user.id, friend_user.id)
          if !friend
            friend = Friend.new
            friend.user_id = @user.id
            friend.friend_id = friend_user.id
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend.facebook_id = auth.uid
            
            friend_request = Friend.find_by_user_id_and_friend_id(friend_user.id, @user.id)
            if friend_request
              friend_request.friend_confirm = true              
              friend.friend_confirm = true
              friend_request.save              
            else
              friend.friend_confirm = false   
              
              if !friend_user.access_key.nil? && !friend_user.access_key.gcm_reg_id.nil?
                auth_user = Authorization.find_by_user_id_and_provider(@user.id, "facebook")
                json = { :friend => { :id => @user.id, :name => @user.name, :username => @user.username, :facebookUID => auth_user.uid, :confirmed => false, :request => true }}
         
                gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)   
                options = { :data => { :title =>"Friend Request", :body => json, :"com.limpidgreen.cinevox.KEY_FRIEND_REQUEST" => true } }
                response = gcm.send([friend_user.access_key.gcm_reg_id], options)    
                p "RESPONSE: " + response.to_yaml       
              end
            end
            
            friend.save
            puts friend.to_yaml
            
            friend_json = { :id => friend_user.id, :name => friend_user.name, :username => friend_user.username, :facebookUID => auth.uid, :confirmed => friend.friend_confirm, :request => false }
          end
        end
      end     
      
      if friend_json 
        render json: { :friend => friend_json }
      else 
        render json: { :friend => { :info => "Error" }}, :status => 403
      end      
    else
      render json: { :friend => { :info => "Error" }}, :status => 403
    end       
  end
  
  def confirm_friend_request 
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "CONFIRM"
      if params[:id].present?  
        friend_user = User.find(params[:id])
        puts "FRIEND USER: " + friend_user.to_yaml
        if friend_user && friend_user.id != @user.id
          friend = Friend.find_by_user_id_and_friend_id(friend_user.id, @user.id)
          if friend
            friend.friend_confirm = true
            friend.save
            
            friend_new = Friend.new
            friend_new.user_id = @user.id
            friend_new.friend_id = friend_user.id
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_new.facebook_id = auth.uid
            friend_new.friend_confirm = true
            friend_new.save
            puts friend_new.to_yaml
            
            if !friend_user.access_key.nil? && !friend_user.access_key.gcm_reg_id.nil?
              auth_user = Authorization.find_by_user_id_and_provider(@user.id, "facebook")
              json = { :friend => { :id => @user.id, :name => @user.name, :username => @user.username, :facebookUID => auth_user.uid, :confirmed => true, :request => false }}
         
              gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)   
              options = { :data => { :title => @user.name + " Accepted your Friend Request", :body => json, :"com.limpidgreen.cinevox.KEY_FRIEND_REQUEST_ACCEPTED" => true } }
              response = gcm.send([friend_user.access_key.gcm_reg_id], options)    
              p "RESPONSE: " + response.to_yaml       
            end
                 
            friend_json = { :id => friend_user.id, :name => friend_user.name, :username => friend_user.username, :facebookUID => auth.uid, :confirmed => true, :request => false }     
          end
        end
      end
      
      if friend_json 
        render json: { :friend => friend_json }
      else 
        render json: { :friend => { :info => "Error" }}, :status => 403 
      end
    else
      render json: { :friend => { :info => "Error" }}, :status => 403
    end 
  end
  
  # GET /friends/1
  # GET /friends/1.json
  def show
  end

  # GET /friends/new
  def new
    @friend = Friend.new
  end

  # GET /friends/1/edit
  def edit
  end

  # POST /friends
  # POST /friends.json
  def create
    @friend = Friend.new(friend_params)

    respond_to do |format|
      if @friend.save
        format.html { redirect_to @friend, notice: 'Friend was successfully created.' }
        format.json { render :show, status: :created, location: @friend }
      else
        format.html { render :new }
        format.json { render json: @friend.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /friends/1
  # PATCH/PUT /friends/1.json
  def update
    respond_to do |format|
      if @friend.update(friend_params)
        format.html { redirect_to @friend, notice: 'Friend was successfully updated.' }
        format.json { render :show, status: :ok, location: @friend }
      else
        format.html { render :edit }
        format.json { render json: @friend.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /friends/1
  # DELETE /friends/1.json
  def destroy
    @friend.destroy
    respond_to do |format|
      format.html { redirect_to friends_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_friend
      @friend = Friend.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def friend_params
      params.require(:friend).permit(:user_id, :friend_id, :facebook_id, :friend_confirm)
    end
    
    def restrict_access
      authenticate_or_request_with_http_token do |token, options|
        p "aUTH"
        @token = token
        AccessKey.exists?(access_token: token)
      end
    end
end
