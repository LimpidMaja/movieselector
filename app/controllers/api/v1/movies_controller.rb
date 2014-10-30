class Api::V1::MoviesController < ApplicationController
  before_filter :restrict_access  
  respond_to :json
  
  include ActionController::HttpAuthentication::Token
  
  def autocomplete
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "AUTOCOMPLETE"
      p "TERM : " +params[:term]
      #render json: Movie.search(params[:query], fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:title)
        
      @hash = []
      @movies= Movie.select("id, title, year, poster").where("lower(title) LIKE ? OR lower(title) LIKE ?", "#{params[:term].downcase}%", "% #{params[:term].downcase}%").limit(10)
      @movies.each do |movie|
        @hash << { "id" => movie.id, "title" => movie.title, "poster" => movie.poster, "year" => movie.year}
      end
      print @hash.to_yaml
    #  render :json => @hash
      respond_with :movies => @hash
      
    else
      render :events => { :info => "Error" }, :status => 403
    end   
  end

  # GET /movies
  # GET /movies.json
  def index
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "INDEx"
    end
  end
  
  def show
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_movie
    @movie = Movie.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def movie_params
    params.require(:movie).permit(:imdb_id, :tmdb_id, :trakt_id, :title, :year, :poster, :imdb_rating, :imdb_num_votes, :plot, :runtime, :language_id, :tagline, :trailer, :term)
  end
  
  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      p "aUTH"
      @token = token
      AccessKey.exists?(access_token: token)
    end
  end
end
