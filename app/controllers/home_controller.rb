class HomeController < ApplicationController
  def autocomplete
    @results = []
    
    results = []

    [Movie, Actor, Genre, Director, Writer, Company, Country].each do |model|
      if model == Movie
        query = Searchkick::Query.new model, params[:query], load: false, fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10      
      else
        query = Searchkick::Query.new model, params[:query], load: false, fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10
      end
      results = results.concat query.execute.response['hits']['hits']      
    end
    
    print results.to_yaml
    
    results.sort_by! { |r| r['_score'] }.reverse!
    map = results.map { |r|    
        if r['_source']['name'] != nil  
          r['_source']['name'] + "(" +  r['_type']  + ")"
        else 
          r['_source']['title'] + "(" +  r['_type']  + ")"
        end                 
      }
    print "MAP \n" + map.to_yaml
    render json: map
    
    
   # @movies =  Movie.search(params[:query], fields: [{title: :word_start},{actors_name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:title)
   # print @movies.to_yaml
   # @movies.map do |model|
    #  print model.to_yaml
  #    model.attributes.slice(:id, :first_name, :last_name).merge(:name => model.name)
   # end
    #@actors = Actor.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
   # print @actors.to_yaml
   
 #   @results = @movies + @actors
    #@results << @actors 
   # print @results.to_yaml
   # render json: @movies
  end
  
  def index
    if params[:query].present?
       # rating_ranges = [{to: 3}, {from: 3, to: 5}, {from: 5, to: 7}, {from: 7}]
        #year_ranges = [{to: 1930}, {from: 1930, to: 1940}, {from: 1940, to: 1950}, {from: 1950, to: 1960}, {from: 1960, to: 1970}, {from: 1970, to: 1980}, {from: 1980, to: 1990}, {from: 1990, to: 2000}, {from: 2000, to: 2010}, {from: 2010}]
        #@movies = Movie.search(params[:query], suggest: true, facets: {imdb_rating: {ranges: rating_ranges}, year: {}, genres_name: {}, actors_name: {}}, page: params[:page], per_page: 50)
        @movies = Movie.search(params[:query], suggest: true, page: params[:page], per_page: 50)
        #print @movies.facets.to_yaml
       # facets: {imdb_rating: {ranges: rating_ranges}}
        @suggestion = @movies.suggestions.first
      else
        trakt = Trakt.new
        trakt.apikey = Rails.application.secrets.trakt_api
        
        trakt_result = trakt.movie.trending
        if trakt_result
          tmdb_ids = []
          trakt_result.each{|m| tmdb_ids << m.tmdb_id}
          order_hash = {}
          tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
          @movies = Movie.where(:tmdb_id => tmdb_ids)
          @movies = @movies.sort_by { |r| order_hash[r.tmdb_id.to_s] }
          @movies =  Kaminari.paginate_array(@movies).page(params[:page]).per(50)         
        end
        print @movies.first.search_data.to_json
        #@movies = Movie.search "*", where: {imdb_num_votes: {gt: 30000}}, order: {imdb_rating: :desc, imdb_num_votes: :desc}, page: params[:page], per_page: 50
        #@movies = Movie.all        
      end
  end  
end
