class MoviesController < ApplicationController
  before_action :set_movie, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Movie.search(params[:query], fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:title)
  end

  # GET /movies
  # GET /movies.json
  def index
    if params[:user_id]
      authenticate_user!
      correct_user_by_user_id?
      @movies = User.find_by_username(params[:user_id]).movies.page(params[:page]).per(48) 
    else
     # @movies = Movie.search "*", where: {imdb_num_votes: {gt: 30000}}, order: {imdb_rating: :desc, imdb_num_votes: :desc}, limit: 20, offset: 0

      if params[:query].present?
        @movies = Movie.search(params[:query], suggest: true, page: params[:page], per_page: 50)
        @suggestion = @movies.suggestions.first
      else
    #    trakt = Trakt.new
    #    trakt.apikey = Rails.application.secrets.trakt_API
        
        #trakt_result = trakt.movie.trending
       # if trakt_result
       #   tmdb_ids = []
       #   trakt_result.each{|m| tmdb_ids << m.tmdb_id}
       #   order_hash = {}
       #   tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
       #   @movies = Movie.where(:tmdb_id => tmdb_ids)
       #   @movies = @movies.sort_by { |r| order_hash[r.tmdb_id.to_s] }
       #   @movies =  Kaminari.paginate_array(@movies).page(params[:page]).per(50)         
       # end
        #@movies = Movie.search "*", where: {imdb_num_votes: {gt: 30000}}, order: {imdb_rating: :desc, imdb_num_votes: :desc}, page: params[:page], per_page: 50
        @movies = Movie.limit(1).page(params[:page]).per(50)      
        #Movie.add_movie(19913, nil, nil)
        
      end
    end
    
    #263698
    # tmdb = Tmdb::Movie.detail(149870)
    #  print tmdb.to_yaml



    #trakt.username = @setting.trakt_username
    #trakt.password = @setting.trakt_password
    #trakt_result = trakt.movie.summary(197962)
    #print trakt_result.to_yaml
    #my_movie = Movie.new
    #     my_movie.trakt_id = trakt_result.url
    #    my_movie.fanart = trakt_result.images.fanart
    #   my_movie.trailer = trakt_result.trailer
    #  print my_movie.to_yaml
 # Movie.add_new_from_tmdb

  end

  # GET /movies/1
  # GET /movies/1.json
  def show
  end
  
  def add_movie_to_watched
    @user = current_user
    movie = Movie.find(params[:movie])
    user_movie = Movie.user_movie_watched(@user, movie.id)  
    if user_movie.nil?
      json_result = {:movie_id => movie.id}
      render json: json_result.to_json
    else
      render json: user_movie.to_json
    end   
  end
  
  def add_movie_to_collection
    @user = current_user
    movie = Movie.find(params[:movie])
    user_movie = Movie.user_movie_collected(@user, movie.id)  
    if user_movie.nil?
      json_result = {:movie_id => movie.id}
      render json: json_result.to_json
    else
      render json: user_movie.to_json
    end      
  end
  
  def add_movie_to_watchlist
    @user = current_user
    movie = Movie.find(params[:movie])
    user_movie = Movie.user_movie_watchlist(@user, movie.id)  
    if user_movie.nil?
      json_result = {:movie_id => movie.id}
      render json: json_result.to_json
    else
      render json: user_movie.to_json
    end     
  end 
    
  # GET /movies/new
  def new
    @movie = Movie.new
  end

  # GET /movies/1/edit
  def edit
  end

  # POST /movies
  # POST /movies.json
  def create
    @movie = Movie.new(movie_params)

    respond_to do |format|
      if @movie.save
        format.html { redirect_to @movie, notice: 'Movie was successfully created.' }
        format.json { render action: 'show', status: :created, location: @movie }
      else
        format.html { render action: 'new' }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /movies/1
  # PATCH/PUT /movies/1.json
  def update
    respond_to do |format|
      if @movie.update(movie_params)
        format.html { redirect_to @movie, notice: 'Movie was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @movie }
      else
        format.html { render action: 'edit' }
        format.json { render json: @movie.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /movies/1
  # DELETE /movies/1.json
  def destroy
    @movie.destroy
    respond_to do |format|
      format.html { redirect_to movies_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_movie
    @movie = Movie.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def movie_params
    params.require(:movie).permit(:imdb_id, :tmdb_id, :trakt_id, :title, :year, :poster, :imdb_rating, :imdb_num_votes, :plot, :runtime, :language_id, :tagline, :trailer)
  end
end
