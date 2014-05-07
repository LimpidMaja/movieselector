class List < ActiveRecord::Base
  has_many :list_movies
  has_many :movies, through: :list_movies


  def self.update_trakt_trending
    trakt = Trakt.new
    trakt.apikey = Rails.application.secrets.trakt_API
    trakt_result = trakt.movie.trending
    if trakt_result
      tmdb_ids = []
      trakt_result.each{|m| tmdb_ids << m.tmdb_id}
      order_hash = {}
      tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
       
      @movies = Movie.where(:tmdb_id => tmdb_ids)
     # @movies = @movies.sort_by { |r| order_hash[r.tmdb_id.to_s] }
      
      trakt_list = List.find_by_name_and_list_type('Trending', 'official')
      if !trakt_list
        trakt_list = List.new
        trakt_list.name = "Trending"        
        trakt_list.description = "Trending Movies based on trakt.tv"
        trakt_list.privacy = "public"
        trakt_list.allow_edit = false
        trakt_list.list_type = "official"
        trakt_list.edit_privacy = "private"
      end 
      
      movie_ids = []
      @movies.each do |movie| 
        if !trakt_list.id.nil?
          list_movie = ListMovie.find_by_list_id_and_movie_id(trakt_list.id, movie.id)
        end
        
        if !list_movie
          list_movie = ListMovie.new
          list_movie.movie_id = movie.id
          list_movie.list_order = order_hash[movie.tmdb_id.to_s]  
          trakt_list.list_movies << list_movie
        else
          list_movie.list_order = order_hash[movie.tmdb_id.to_s]  
          list_movie.save
        end
        movie_ids << movie.id  
        logger.info "\nHASH: "  + order_hash[movie.tmdb_id.to_s].to_s 
        logger.info "\nMovie: " + movie.title + " ORDER: " + list_movie.list_order.to_s
        
      end
      
      movies_for_destroy = ListMovie.where.not(:movie_id => movie_ids).where(:list_id => trakt_list.id)
      
      logger.info "movies_for_destroy; " + movies_for_destroy.to_yaml
      movies_for_destroy.destroy_all
      
      logger.info "LIST:; " + trakt_list.to_yaml
      trakt_list.save
    end 
  end
end