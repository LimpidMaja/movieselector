class FriendsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :correct_user?
  before_action :set_friend, only: [:show, :edit, :update, :destroy]

 def autocomplete    
    print "TEST events" 
    render json: Movie.search(params[:query], fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:title)
  end
  
  # GET /friends
  # GET /friends.json
  def index
    @user = current_user
    
    @friend_requests = Friend.where(:friend_id => @user.id, :friend_confirm => false)
    @friend_requests.each do |friend|
      friend_user = User.find_by_id(friend.user_id)
      friend.name = friend_user.name
      auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
      friend.facebook_id = auth.uid
      friend.username = friend_user.username
      friend.picture = "http://graph.facebook.com/" + friend.facebook_id + "/picture"   
    end
    
    @friends = @user.friends
    @friends.each do |friend|
      if friend.friend_confirm == true
        friend_user = User.find_by_id(friend.friend_id)
        friend.name = friend_user.name
        auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
        friend.facebook_id = auth.uid
        friend.picture = "http://graph.facebook.com/" + friend.facebook_id + "/picture" 
        friend.friend_user_id = friend_user.id     
      end
    end
    puts @friends.to_yaml
  end
  
  def find
    @user = current_user
    auth = Authorization.find_by_user_id_and_provider(@user.id, "facebook")        
    @graph = Koala::Facebook::API.new(auth.access_token, Rails.application.secrets.omniauth_provider_secret.to_s)
    #friends = @graph.get_connections("me", "friends")
    #friend.each do |friend| 
      
    #end
    @friends = []
    
    if !@graph.nil?
      begin
        friends_fb = @graph.get_connections("me", "friends")
        #p "\n FRIENDS: " + friends_fb.to_yaml    
        #iris 10152845525454851
        #primoz 694717864
        begin        
         #logger.info "\n @next_page " + videos.to_yaml
         if !friends_fb.nil?        
            count = friends_fb.count
            friends_fb.each do |friend|    
              if !friend.nil?
                #logger.info "\n FRIEND: " + friend.name.to_yaml    
                fb_friend = Friend.new
                fb_friend.name = friend.name
                fb_friend.facebook_id = friend.id
                fb_friend.picture = "http://graph.facebook.com/" + friend.id + "/picture"
                auth = Authorization.find_by_uid(friend.id)                
                if auth
                  friend_user = auth.user
                  fb_friend.friend_user_id = friend_user.id
                end
                @friends << fb_friend             
              end 
            end               
          end         
        end while friends_fb = friends_fb.next_page                
      rescue => e
        logger.error "\n FACEBOOK FRIENDS RESULT ERROR: " + e.to_s + "\n"
      end
    end
    #puts @friends.to_yaml
    render :index
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
end
