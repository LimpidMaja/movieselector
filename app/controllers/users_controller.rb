class UsersController < ApplicationController
  before_filter :authenticate_user!
  before_filter :correct_user?, :except => [:index]

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
   # logger.info " \n SESSION: " + session.to_json + "\n"
    
    if params[:query].present? && !params[:query].blank?
      array = params[:query].split(/[,]/); 
      @movies = Movie.search_movie(array, @user, params[:page], 48, params[:watched], params[:only_collected], false, true)
    else 
      @movies = Movie.search_movie(nil, @user, params[:page], 48, params[:watched], true, false, true)
    end
  end
  
  def library
    @user = current_user
    @movies = Movie.search_movie(nil, @user, params[:page], 48, params[:watched], true, false, true)
    render :show
  end
  
  def watchlist
    @user = current_user
    @movies = Movie.search_movie(nil, @user, params[:page], 48, params[:watched], false, true, true)
    render :show
  end
  
  def lists
    @user = current_user
    @lists = List.find_by_user(@user)
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
