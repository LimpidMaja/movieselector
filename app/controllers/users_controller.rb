class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :correct_user?, :except => [:index, :show, :follow, :confirm_friend, :library, :watched, :watchlist, :lists, :list, :friends]

  def index
    @users = User.all
  end

  def edit
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end
  end

  def update
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end
    if @user.update_attributes(secure_params)
      redirect_to @user
    else
      render :edit
    end
  end

  def show  
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end    
    
    @user = header(@user)   
    
    auth = Authorization.find_by_uid(@user.id)         
    puts "USER: " + @USER.name + " FB ID: " + auth.uid
    if current_user == @user || @user.setting.private == false   
      @movies = Movie.user_movie_latest_watched(@user, current_user)
    end
    #if params[:query].present? && !params[:query].blank?
    #  array = params[:query].split(/[,]/); 
    #  @movies = Movie.search_movie(array, @user, params[:page], 48, params[:watched], params[:only_collected], false, true)
    #else 
    #  @movies = Movie.search_movie(nil, @user, params[:page], 48, params[:watched], true, false, true)
    #end
  end
  
  def header(user)
    auth = Authorization.find_by_user_id_and_provider(user.id, "facebook")        
    @graph = Koala::Facebook::API.new(auth.access_token, Rails.application.secrets.omniauth_provider_secret.to_s)
    if !@graph.nil?
      begin
        picture = @graph.get_connections("me", "picture?redirect=0&height=200&type=normal&width=200")
        begin        
         if !picture.nil? && !picture.data.nil?         
            user.picture = picture.data.url
          end
        end
      end
    end
    
    user.watched = UserMovie.where(:user => @user, :watched => true).count
    user.collected = UserMovie.where(:user => @user, :collection => true).count
    
    if !current_user.nil? 
      if current_user.id != user.id && Friend.where(:user_id => current_user.id, :friend_id => user.id).empty?
        @follow = true
      end
    end
    
    return user
  end
  
  def watched
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end   
    
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
          
    @user = header(@user)     
        
    #@movies = Movie.user_movie_watched(@user, current_user, params[:page], 48)
    @movies = Movie.search_movie(nil, @user, current_user, params[:page], 48, true, nil, nil, true)
    render :library
  end
  
  def library
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end   
    
    puts "IS PRIVATE: " +  @user.setting.private.to_yaml
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
          
    @user = header(@user)     
    
    @movies = Movie.search_movie(nil, @user, current_user, params[:page], 48, params[:watched], true, false, true)
    render :library
  end
  
  def watchlist
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end  
    
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
    
    @user = header(@user)    
        
    @movies = Movie.search_movie(nil, @user, current_user, params[:page], 48, params[:watched], false, true, true)
    render :library
  end
  
  def lists
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end   
    
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
              
    @user = header(@user)    
            
    @lists = List.where(:user_id => @user.id).page(params[:page]).per(25)
    render 'lists/index'
  end
  
  def list
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end   
    
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
              
    @user = header(@user)    
            
    @list = List.find_by_id(params[:list_id])
    @movies = Movie.includes(:list_movies).where("list_movies.list_id = ?", @list.id).references(:list_movies).order("list_movies.list_order ASC").page(params[:page]).per(48) 
   
    render 'lists/show'
  end
  
  def friends
    if params[:user_id]
      @user = User.find_by_username(params[:user_id])
    else
      @user = User.find_by_username(params[:id])
    end   
    
    if current_user != @user && @user.setting.private == true
      redirect_to root_url, :alert => "Access denied."
      return
    end
              
    @user = header(@user)    
    
    if current_user == @user 
      @friend_requests = Friend.where(:friend_id => @user.id, :friend_confirm => false)
      @friend_requests.each do |friend|        
        friend_user = User.find_by_id(friend.user_id)
        auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
        friend.name = friend_user.name
        friend.facebook_id = auth.uid
        friend.username = friend_user.username
        friend.picture = "http://graph.facebook.com/" + friend.facebook_id + "/picture"   
      end
    end 
    
    @friends = @user.friends
    @friends.each do |friend|
      if friend.friend_confirm == true
        friend_user = User.find_by_id(friend.friend_id)
        auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
        friend.name = friend_user.name
        friend.facebook_id = auth.uid
        friend.picture = "http://graph.facebook.com/" + friend.facebook_id + "/picture" 
        friend.friend_user_id = friend_user.id     
      end
    end
    
    render 'friends/index'
  end
  
  def follow
    puts "FOLLOW"
    if params[:id].present?      
      @user = current_user
      friend_user = User.find_by_username(params[:id])
      puts "FRIEND USER: " + friend_user.to_yaml
      if friend_user && friend_user.id != @user.id
        friend = Friend.find_by_user_id_and_friend_id(@user.id, friend_user.id)
        if !friend
          friend = Friend.new
          friend.user_id = @user.id
          friend.friend_id = friend_user.id
          auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
          friend.facebook_id = auth.uid
          friend.friend_confirm = false
          friend.save
          puts friend.to_yaml
        end
      end
    end
    render json: "[]"
  end
  
  def confirm_friend
    puts "comfirm_friend"
    if params[:id].present?      
      @user = current_user
      friend_user = User.find_by_username(params[:id])
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
          friend_request = Friend.find_by_user_id_and_friend_id(friend_user.id, @user.id)
          if friend_request
            friend_request.friend_confirm = true              
            friend.friend_confirm = true
            friend_request.save
          else
            friend.friend_confirm = false              
          end
          friend_new.save
          puts friend_new.to_yaml
        end
      end
    end
    render json: "[]"
  end
  
  #helper_method :update_movies(user)
  #def update_movies    
  #  require 'trakt'
  #  require 'omdbapi'
        
  #  trakt = Trakt.new
  #  trakt.apikey = '10cb2611225067227cb1da6fcb4be6f9'
  #  trakt.username = 'LimpidMaja'
  #  trakt.password = '755MK7ap'
    
   # @result = trakt.activity.collection(trakt.username)
    
   # @result.each do |movie|
     # print movie['imdb_id']
   #   imdb = OMDB.id(movie['imdb_id'])
   #   print imdb.title
   #   print " "
  #    print imdb.imdb_rating
  #    print " \n"
  #  end
   #  
    # render :show
  #end

  private

  def secure_params
    params.require(:user).permit(:email).permit(:user_id)
  end

end
