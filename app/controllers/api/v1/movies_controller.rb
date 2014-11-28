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
  
  def collection
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "Collection"
      if params[:term].present?
        p "TERM : " +params[:term]
        @user_movies = UserMovie.where("user_id = ? AND collection = true", @user.id)
        @movies = Movie.select("id, title, year, poster, release_date, imdb_rating").where("id IN (?) AND (lower(title) LIKE ? OR lower(title) LIKE ?)", @user_movies.map(&:movie_id), "#{params[:term].downcase}%", "% #{params[:term].downcase}%").limit(10)     
      else
        @user_movies = UserMovie.where("user_id = ? AND collection = true", @user.id)
        @movies = Movie.select("id, title, year, poster, release_date, imdb_rating").where("id IN (?)", @user_movies.map(&:movie_id)).order("title")
      end
        
      @hash = []
      @movies.each do |movie|
        @hash << { "id" => movie.id, "title" => movie.title, "poster" => movie.poster, "year" => movie.year, "release_date" => movie.release_date, "imdb_rating" => movie.imdb_rating}
      end
      print @hash.to_yaml
      respond_with :movies => @hash      
    else
      render :events => { :info => "Error" }, :status => 403
    end   
  end
  
  def search_lists
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "AUTOCOMPLETE"
      p "TERM : " +params[:term]
            
      keyword = params[:term]
      
      @lists = []      
      @results = []    
         
      # Google search      
      require 'google_search'
      require 'rubygems'
      require 'nokogiri'
      require 'open-uri'
      
      begin
        results = GoogleSearch.web :q => keyword + " site:imdb.com/list"
        results.responseData.results.each do |result|
          url = result.url
  
          list = List.new()
          name = result.titleNoFormatting
          if name.index(' - a list by') != nil
            list.name = name[6, name.index(' - a list by') - 6]
          elsif name.index(' - a ...') != nil
            list.name = name[6, name.index(' - a ...') - 6]
          else 
            list.name = name
          end
                    
          list.url = url
          list.movies = []
          list.list_movies = []
          @lists << list
        end
      rescue GoogleSearchError
        puts "GOOGLE SEARCH ERROR"
      end
      #end Google search
     
      # Google Custom API Search
      if @lists.empty?
        begin
          require 'google/api_client'
          require 'google/api_client/client_secrets'
          require 'google/api_client/auth/installed_app'
                ####
          @client = Google::APIClient.new(
            key: 'AIzaSyBXLE2IBXVhBkHa3ge_jPtqh07Xw7I_b5w', authorization: nil)
          @search = @client.discovered_api('customsearch')
          
          result = @client.execute(api_method: @search.cse.list, parameters: {q: keyword, 
                         key: 'AIzaSyBXLE2IBXVhBkHa3ge_jPtqh07Xw7I_b5w',
                         cx: '004001024232679184917:1q83jpmtdoq'})
                                 
          result.data.items.each do |item|
            list = List.new()   
            name = item.title
            if name.index(' - a list by') != nil
              list.name = name[6, name.index(' - a list by') - 6]
            elsif name.index(' - a ...') != nil
              list.name = name[6, name.index(' - a ...') - 6]
            else 
              list.name = name
            end
                      
            list.url = item.link
            list.movies = []
            list.list_movies = []          
            @lists << list 
          end  
        rescue GoogleSearchError
          puts "GOOGLE CUSTOM SEARCH API ERROR"
        end       
      end
      # Google Custom API Search
           
      @lists.each do |movie_list|
        doc = Nokogiri::HTML(open(movie_list.url))

        news_links = doc.css("div").select{|link| link['class'] == "info"}
        c = 1
        news_links.each do |info|
          links = info.css("a")
          links.each do |link|
            if link.to_s.include? "onclick"
              title = link["href"].split('/')[2]    
              
              if title.start_with?('tt')          
                movie = Movie.find_by_imdb_id(title)
                
                if movie
                  list_movie = ListMovie.new()
                  list_movie.movie = movie
                  list_movie.list_order = c
                  movie_list.list_movies << list_movie
                  c = c + 1
                  break;
                end
              end
            end
          end
        end
        
        if movie_list.list_movies.size > 0
          @results << movie_list
        end
      end
           
      @hash = []
      @results.each do |movie_list|  
        puts "TITLE " + movie_list.name 
        
        movies = []
        movie_list.list_movies.each do |list_movie|
          puts "MOVEI: " +  list_movie.movie.title
          movies << { "id" => list_movie.movie.id, "title" => list_movie.movie.title, "poster" => list_movie.movie.poster, "year" => list_movie.movie.year}
        end
        
        
        @hash << { "title" =>  movie_list.name, "movies" => movies}
      end       
          
      print @hash.to_yaml
    #  render :json => @hash
      respond_with :lists => @hash
      
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
