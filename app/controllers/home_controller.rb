class HomeController < ApplicationController
  def autocomplete
    @results = []
    print "\n AUTOCOMPLETE: " + params[:term].to_s + " \n"
    results = []

    [Movie, Actor, Genre, Director, Writer, Company, Country].each do |model|
      if model == Movie
        query = Searchkick::Query.new model, params[:term], load: false, fields: [{title: :word_start}], misspellings: {distance: 2}, limit: 10      
      else
        query = Searchkick::Query.new model, params[:term], load: false, fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10
      end
      results = results.concat query.execute.response['hits']['hits']      
    end
    
   # print results.to_yaml
    
    results.sort_by! { |r| r['_score'] }.reverse!
    map = results.map { |r|    
        if r['_source']['name'] != nil  
          r['_source']['name'] #+ "(" +  r['_type']  + ")"
        else 
          r['_source']['title']# + "(" +  r['_type']  + ")"
        end                 
      }
    print "MAP \n" + map.to_yaml
    render json: map.uniq.first(10)
    
    
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
     @user = current_user
     print "\nCURRETNT CUSER: "+ @user.to_yaml 
   
    if params[:query].present? && !params[:query].blank?
      array = params[:query].split(/[,]/); 
      @movies = Movie.search_movie(array, @user, params[:page], 48, false, false, false, false)
    else 
      @movies = Movie.search_movie(nil, @user, params[:page], 48, false, false, false, false)
    end

        # rating_ranges = [{to: 3}, {from: 3, to: 5}, {from: 5, to: 7}, {from: 7}]
        #year_ranges = [{to: 1930}, {from: 1930, to: 1940}, {from: 1940, to: 1950}, {from: 1950, to: 1960}, {from: 1960, to: 1970}, {from: 1970, to: 1980}, {from: 1980, to: 1990}, {from: 1990, to: 2000}, {from: 2000, to: 2010}, {from: 2010}]
        #@movies = Movie.search(params[:query], suggest: true, facets: {imdb_rating: {ranges: rating_ranges}, year: {}, genres_name: {}, actors_name: {}}, page: params[:page], per_page: 50)
        #where: {imdb_num_votes: {gt: 10000}, missing_data: {not: 1}}
        #print "\n FIRST: " + Movie.first.search_data.to_json
        #imdb_num_votes: {gt: 500},  
  end  
end
