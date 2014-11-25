class List < ActiveRecord::Base
  has_many :list_movies
  has_many :movies, through: :list_movies

  attr_accessor :url
  attr_accessor :img

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
  
  def self.update_imdb_top_250
    trakt = Trakt.new
    trakt.apikey = Rails.application.secrets.trakt_API
    trakt_result = trakt.account.list('mmounirou', 'imdb-best-250-movies')
    if trakt_result
      trakt_result = trakt_result.items
      tmdb_ids = []
      trakt_result.each{|m| tmdb_ids << m.movie.tmdb_id}
      order_hash = {}
      tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
       
      @movies = Movie.where(:tmdb_id => tmdb_ids)
      trakt_list = List.find_by_name_and_list_type('IMDB Top 250', 'official')
      if !trakt_list
        trakt_list = List.new
        trakt_list.name = "IMDB Top 250"        
        trakt_list.description = "IMDB Top 250"
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
      end
      
      movies_for_destroy = ListMovie.where.not(:movie_id => movie_ids).where(:list_id => trakt_list.id)
      
      movies_for_destroy.destroy_all
      
      trakt_list.save
    end 
  end
  
  def self.update_tmdb_upcoming
    upcoming_movies = Tmdb::Movie.upcoming
    logger.info " \n UPCOMING: " +  upcoming_movies.to_yaml  + "\n"
    if upcoming_movies
      tmdb_ids = []
      upcoming_movies.each{|m| tmdb_ids << m.id}
      order_hash = {}
      tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
       
   #   upcoming_movies.each do |m|        
    #    Movie.add_movie(m.id, nil, true)
    #  end 
       
      @movies = Movie.where(:tmdb_id => tmdb_ids)
     # @movies = @movies.sort_by { |r| order_hash[r.tmdb_id.to_s] }
      
      upcoming_list = List.find_by_name_and_list_type('Upcoming', 'official')
      if !upcoming_list
        upcoming_list = List.new
        upcoming_list.name = "Upcoming"        
        upcoming_list.description = "Upcoming Movies based on themoviedb"
        upcoming_list.privacy = "public"
        upcoming_list.allow_edit = false
        upcoming_list.list_type = "official"
        upcoming_list.edit_privacy = "private"
      end 
      
      movie_ids = []
      @movies.each do |movie| 
        if !upcoming_list.id.nil?
          list_movie = ListMovie.find_by_list_id_and_movie_id(upcoming_list.id, movie.id)
        end
        
        if !list_movie
          list_movie = ListMovie.new
          list_movie.movie_id = movie.id
          list_movie.list_order = order_hash[movie.tmdb_id.to_s]  
          upcoming_list.list_movies << list_movie
        else
          list_movie.list_order = order_hash[movie.tmdb_id.to_s]  
          list_movie.save
        end
        movie_ids << movie.id  
        logger.info "\nHASH: "  + order_hash[movie.tmdb_id.to_s].to_s 
        logger.info "\nMovie: " + movie.title + " ORDER: " + list_movie.list_order.to_s
        
      end
      
      movies_for_destroy = ListMovie.where.not(:movie_id => movie_ids).where(:list_id => upcoming_list.id)
      
      logger.info "movies_for_destroy; " + movies_for_destroy.to_yaml
      movies_for_destroy.destroy_all
      
      logger.info "LIST:; " + upcoming_list.to_yaml
      upcoming_list.save
    end 
  end
end