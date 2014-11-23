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
  
  def search_lists
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "AUTOCOMPLETE"
      p "TERM : " +params[:term]
      
      
      keyword = params[:term]
      
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
                     
      puts "RESULT"
      puts result.data.to_yaml
      puts "RSULT END"
                     
      ###
      
      @lists = []

      require 'google_search'
      require 'rubygems'
      require 'nokogiri'
      require 'open-uri'

      
      imdb_id_list = {}

=begin
      i = 1
      results = GoogleSearch.web :q => keyword + " site:imdb.com/list"
      results.responseData.results.each do |result|
        url = result.url
        puts url
        puts result.titleNoFormatting

        imdb_id_list[result.titleNoFormatting] = []

        list = List.new()
        name = result.titleNoFormatting
        if name.index(' - a list by') != nil
          list.name = name[0, name.index(' - a list by')]
        elsif name.index(' - a ...') != nil
          list.name = name[0, name.index(' - a ...')]
        else 
          list.name = name
        end
        list.movies = []
        list.list_movies = []
        
        puts " "
        doc = Nokogiri::HTML(open(url))

        news_links = doc.css("div").select{|link| link['class'] == "info"}
        c = 1
        news_links.each do |info|
          puts "NEW: " + i.to_s

          links = info.css("a")
          links.each do |link|
            if link.to_s.include? "onclick"
              puts link["href"]
              title = link["href"].split('/')[2]
              puts title
              imdb_id_list[result.titleNoFormatting] << title

              movie = Movie.find_by_imdb_id(title)
              
              if movie
                puts "Movie:"
                puts movie
                list_movie = ListMovie.new()
                list_movie.movie = movie
                list_movie.list_order = c
                list.list_movies << list_movie
                #puts "LM: " + list_movie.to_yaml
                c = c + 1
                break;
              end
            end
          end

          puts " "

          i = i + 1
        end
       
        
        #if list.list_movies.size > 0
          @lists << list
        #end
      end
=end 
      puts imdb_id_list
      #puts @lists[0].movies.to_yaml
      @lists.each do |list|  
        puts "NAME: " + list.name        
        puts " TITLES: "
        puts "COUNT: " + list.list_movies.size.to_s
        #puts list.list_movies[0].movie.to_yaml
        list.list_movies.each do |list_movie|
          puts "M: " +  list_movie.movie.to_yaml
        end
      end       
      
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
