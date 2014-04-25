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
    #@tmdb = Tmdb::Movie.latest.to_yaml#Tmdb::Movie.detail(263693).to_yaml#Tmdb::Movie.latest.to_yaml#
    
    @movies = @user.movies
     #print " \n"
     #*user_movie = @user.user_movies.find_by_movie_id(1)
     #user_movie.watched = false
    #user_movie.collection = true
    # user_movie.date_watched = DateTime.current
    # user_movie.save
     ##print " \n"
    
    #@movies.each do |movie|
     # print " \n"
    # print movie.user_movie
     #print " \n"
      #user_movie = UserMovie.find(user_id: @user.id, movie_id: movie.id)
     # user_movie.watched = false
     # user_movie.collection = true
     # user_movie.date_watched = Date.current
      #user_movie.save
   # end
   #@movies = @user.movies
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
