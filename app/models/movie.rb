class Movie < ActiveRecord::Base
  extend FriendlyId
  friendly_id :title, use: :slugged
  has_and_belongs_to_many :genres, :join_table => :movies_genres
  has_and_belongs_to_many :keywords, :join_table => :movies_keywords
  has_and_belongs_to_many :languages, :join_table => :movies_languages
  has_and_belongs_to_many :countries, :join_table => :movies_countries
  has_and_belongs_to_many :directors, :join_table => :movies_directors
  has_and_belongs_to_many :companies, :join_table => :movies_companies
  has_many :movie_writers
  has_many :writers, through: :movie_writers
  has_many :movie_actors
  has_many :actors, through: :movie_actors
  has_many :user_movies
  has_many :users, through: :user_movies
  has_many :list_movies
  has_many :lists, through: :list_movies
  has_many :showtimes  
        
  has_many :event_user_votes
  
  attr_accessor :watched
  attr_accessor :collected
  attr_accessor :watchlist
  attr_accessor :voting_score
  
  #after_initialize :set_attr

  #def set_attr
  #  @seen = true
 # end
  
 # def seen=(boolean)
 #    boolean
  # end
  
 # def seen=(seen)
 #   @seen= seen
 # end
  searchkick word_start: [:title, :original_title], suggest: [:title, :actors_name, :original_title, :directors_name, :writers_name, :companies_name, :genres_name, :countries_name]

  def search_data
    {
      title: title,
      imdb_id: imdb_id,
      tmdb_id: tmdb_id,
      original_title: original_title,
      imdb_rating: imdb_rating,
      imdb_num_votes: imdb_num_votes,
      plot: plot,
      tagline: tagline,
      year: year,
      runtime: runtime,
      status: status,
      missing_data: missing_data,
      awards: awards,
      actors_name: actors.map(&:name),
      directors_name: directors.map(&:name),
      writers_name: writers.map(&:name),
      companies_name: companies.map(&:name),
      genres_name: genres.map(&:name),
      countries_name: countries.map(&:name),
      languages_name: languages.map(&:name),
      keywords_name: keywords.map(&:name)
    }
  end
 
  def self.sync_facebook(user)
    logger.info "\n SYNC FACEBOOK"
    auth = Authorization.find_by_user_id_and_provider(user.id, "facebook")        
    @graph = Koala::Facebook::API.new(auth.access_token, Rails.application.secrets.omniauth_provider_secret.to_s)
            
    if !@graph.nil?
      begin
        videos = @graph.get_connections("me", "video.watches?fields=data")
        
        begin        
          #logger.info "\n @next_page " + videos.to_yaml  
          if !videos.nil?     
            logger.info "\n videos " + videos.to_yaml       
            count = videos.count
            found = 0
            not_found = 0 
            videos.each do |movie| 
              if !movie.data['movie'].nil?
                title = movie.data.movie.title
                my_movie = Movie.find_by_title(title)                
                
                if my_movie                  
                  found += 1
                  update_user_movie(user, my_movie, true, nil, nil)
                else              
                  not_found += 1 
                end              
              end 
            end  
            logger.info "\n NOT FOUND: " + not_found.to_s  
            logger.info "\n FOUND: " + found.to_s                
          end         
        end while videos = videos.next_page
                
      rescue => e
        logger.error "\n FACEBOOK WATCHED RESULT ERROR: " + e.to_s + "\n"
      end
      
      begin
        videos = @graph.get_connections("me", "video.wants_to_watch?fields=data")
        
        begin        
          #logger.info "\n @next_page " + videos.to_yaml  
          if !videos.nil?     
            logger.info "\n videos " + videos.to_yaml       
            count = videos.count
            found = 0
            not_found = 0 
            videos.each do |movie| 
              if !movie.data['movie'].nil?
                title = movie.data.movie.title
                my_movie = Movie.find_by_title(title)                
                
                if my_movie                  
                  found += 1
                  update_user_movie(user, my_movie, nil, nil, true)
                else              
                  not_found += 1 
                end              
              end 
            end  
            logger.info "\n NOT FOUND: " + not_found.to_s  
            logger.info "\n FOUND: " + found.to_s                
          end         
        end while videos = videos.next_page
                
      rescue => e
        logger.error "\n FACEBOOK WANT TO WATCH RESULT ERROR: " + e.to_s + "\n"
      end
    end    
  end
  
  def self.sync_trakt(user)
    @setting = user.setting
    print "\n username:"
    print @setting.trakt_username
    require 'trakt'
    if !@setting.trakt_username.nil? && !@setting.trakt_password.nil?
      trakt = Trakt.new
      trakt.apikey = Rails.application.secrets.trakt_API
      trakt.username = @setting.trakt_username
      trakt.password = @setting.trakt_password
      
      begin  
        trakt_result = trakt.account.movies_all(trakt.username, 'min')            
        if trakt_result
          id_map = []
          trakt_result.each do |movie|           
            tmdb_id = movie.tmdb_id
            my_movie = add_movie(tmdb_id, movie, nil)
            if my_movie
              id_map << my_movie.id
              if movie.plays > 0
                watched = true
              else
                watched = false
              end
              update_user_movie(user, my_movie, watched, movie.in_collection, nil)
            end 
          end  
          
          user_movies = UserMovie.where(user_id: user.id, collection: false, watched: false, watchlist: false)
          user_movies.each do |user_movie|
            if !user_movie.watched
              logger.info "\n TITLE TO DELETE: " + user_movie.movie.title
              user_movie.destroy
            end
          end
        end
      rescue => e
        logger.error "\n TRAKT ALL RESULT ERROR: " + e.to_s + "\n"
      end
      
      begin
        #add date added
        trakt_collection_result = trakt.account.movies_collection(trakt.username, 'min')         
        if trakt_collection_result
          require 'date'
          trakt_collection_result.each do |movie|
            tmdb_id = movie.tmdb_id
            my_movie = Movie.find_by_tmdb_id(tmdb_id)            
            if my_movie                
              user_movie = UserMovie.where(user_id: user.id, movie_id: my_movie.id).limit(1).first
              if user_movie
                puts user_movie.to_yaml 
                user_movie.date_collected = DateTime.strptime(movie.collected.to_s,'%s')
                puts user_movie.date_collected.to_s
                user_movie.save
              end
            end 
          end
        end        
        #end add date added
      rescue => e
        logger.error "\n TRAKT COLLECTED RESULT ERROR: " + e.to_s + "\n"
      end
=begin     
      begin
        trakt_wathed_result = trakt.activity.watched(trakt.username)
        if trakt_wathed_result
          trakt_wathed_result.each do |movie|
            tmdb_id = movie.tmdb_id
            my_movie = add_movie(tmdb_id, movie, nil)
            if my_movie
              update_user_movie(user, my_movie, true, nil, nil)
            end 
          end          
        end
      rescue => e
        logger.error "\n TRAKT WATCHED RESULT ERROR: " + e.to_s + "\n"
      end
=end    
    end
  end
  
  def self.add_new_from_tmdb
    count = 0
    requests = 0
    start_time = Time.new
    start_id = Movie.last.tmdb_id
    end_id = Tmdb::Movie.latest.id
    (start_id.to_i..end_id.to_i).each do |i|
      logger.info "COUNT: " + count.to_s
      logger.info "MOVIE ID: " + i.to_s   
      if requests > 26
        seconds = Time.new - start_time
        if seconds < 10
          logger.info "SLEEP!"
          sleep 10
        end
        start_time = Time.new
        requests = 0
      end
      @movie = add_movie(i, nil, nil) 
      if @movie   
        count += 1
      end
      requests += 3      
    end
  end
  
  def self.add_movie_with_imdb(imdb_result, poster, directors)
    if imdb_result.present?
      if !imdb_result.id.nil? && !imdb_result.id.blank?      
        logger.info "MOVIE BY IMDB ID"      
        my_movie = Movie.find_by_imdb_id('tt' + imdb_result.id)
      end
      if (!my_movie)
        my_movie = Movie.new        
        my_movie.missing_data = true
        my_movie.imdb_id = 'tt' + imdb_result.id
        my_movie.poster = imdb_result.poster unless imdb_result.poster == 'N/A'
        if !my_movie.poster
          my_movie.poster = poster
        end
        my_movie.runtime = imdb_result.length
        my_movie.plot = imdb_result.plot
        my_movie.rated = imdb_result.mpaa_rating unless imdb_result.mpaa_rating == 'N/A'
        my_movie.title = imdb_result.title(true)
        my_movie.year = imdb_result.year
        my_movie.release_date = imdb_result.release_date
        my_movie.imdb_rating = imdb_result.rating
        my_movie.imdb_num_votes = imdb_result.votes.to_i
        my_movie.tagline = imdb_result.tagline
        
        puts "GENRES: " + imdb_result.genres.to_yaml
        imdb_result.genres.each do |genre|
          my_genre = Genre.find_by_name(genre.strip)
          if !my_genre
            my_genre = Genre.new
            my_genre.name = genre.strip
            my_genre.save
          end
          my_movie.genres << my_genre unless !my_movie.genres.find{|item| item[:name] == my_genre.name}.nil?
        end
        
        puts "COUNTRIES: " + imdb_result.countries.to_yaml
        imdb_result.countries.each do |country|
          my_country = Country.find_by_name(country.strip)
          if !my_country
            my_country = Country.new
            my_country.name = country
            my_country.save
          end
          my_movie.countries << my_country unless !my_movie.countries.find{|item| item[:name] == my_country.name}.nil?
        end
        
        if directors
          directors.each do |director|            
            my_director = Director.find_by_name(director.strip)
            if !my_director
              my_director = Director.new
              my_director.name = director.strip              
              my_director.save
            end
            my_movie.directors << my_director unless !my_movie.directors.find{|item| item[:name] == my_director.name}.nil?
          end
        end
        
        logger.info "MY MOVIE: \n"
        logger.info my_movie.to_yaml
        logger.info "\n END \n"
        my_movie.save
        return my_movie
      end
    end
  end
  
  def self.add_movie_with_omdb(imdb_result)
    if imdb_result.present?
      if !imdb_result.imdb_id.nil? && !imdb_result.imdb_id.blank?      
        logger.info "MOVIE BY IMDB ID"      
        my_movie = Movie.find_by_imdb_id(imdb_result.imdb_id)
      end
      if (!my_movie)
        my_movie = Movie.new        
        my_movie.missing_data = true
        my_movie.imdb_id = imdb_result.imdb_id
        my_movie.rated = imdb_result.rated unless imdb_result.rated == 'N/A'
        my_movie.poster = imdb_result.poster unless imdb_result.poster == 'N/A'
        my_movie.runtime = imdb_result.runtime unless imdb_result.runtime.to_i < 5
        my_movie.plot = imdb_result.plot
        my_movie.title = imdb_result.title
        my_movie.year = imdb_result.year
        my_movie.release_date = imdb_result.released
        my_movie.imdb_rating = imdb_result.imdb_rating
        imdb_result.imdb_votes.gsub!(',','') if imdb_result.imdb_votes.is_a?(String)
        my_movie.imdb_num_votes = imdb_result.imdb_votes.to_i
        my_movie.awards = imdb_result.awards unless imdb_result.awards == 'N/A'
        
        if imdb_result.genre
          genres = imdb_result.genre.split(',')
          puts "GENRES: " + genres.to_yaml
          genres.each do |genre|
            my_genre = Genre.find_by_name(genre.strip)
            if !my_genre
              my_genre = Genre.new
              my_genre.name = genre.strip
              my_genre.save
            end
            my_movie.genres << my_genre unless !my_movie.genres.find{|item| item[:name] == my_genre.name}.nil?
          end
        end
        
        logger.info "MY MOVIE: \n"
        logger.info my_movie.to_yaml
        logger.info "\n END \n"
        my_movie.save
        return my_movie
      end
    end
  end
    
  def self.add_movie(tmdb_id, movie, update_imdb)
    if tmdb_id.present?
      logger.info "MOVIE BY TMDB ID"
      my_movie = Movie.find_by_tmdb_id(tmdb_id)
    end
    if !my_movie && movie.present? && !movie['imdb_id'].nil? && !movie['imdb_id'].blank?      
      logger.info "MOVIE BY TRAKT IMDB ID"      
      my_movie = Movie.find_by_imdb_id(movie['imdb_id'])
    end
    if !my_movie && movie.present? && !movie['tmdb_id'].nil? && !movie['tmdb_id'].blank?         
      logger.info "MOVIE BY TRAKT TMDB ID"
      my_movie = Movie.find_by_tmdb_id(movie['tmdb_id'])
    end
    
    tmdb_id = movie['tmdb_id'] unless tmdb_id.present?
    
    if (!my_movie || my_movie.missing_data == true)
      tmdb = Tmdb::Movie.detail(tmdb_id) 
      if tmdb && tmdb.id && tmdb.adult == false
        if !my_movie
          my_movie = Movie.new
          logger.info "NEW MOVIE"
        end
        my_movie.missing_data = false
        
        if !tmdb.original_title.nil? && !tmdb.original_title.empty?
          if my_movie.original_title.nil? || my_movie.original_title.empty? || my_movie.original_title != tmdb.original_title
            my_movie.original_title = tmdb.original_title
          end
        end
        if !tmdb.budget.nil? && tmdb.budget > 0 
          if my_movie.budget.nil? || my_movie.budget == 0 || tmdb.budget.to_i != my_movie.budget.to_i
            my_movie.budget = tmdb.budget
          end 
        end
        if !tmdb.revenue.nil? && tmdb.revenue > 0
          if my_movie.revenue.nil? || my_movie.revenue == 0 || my_movie.revenue.to_i != tmdb.revenue.to_i
            my_movie.revenue = tmdb.revenue
          end
        end
        if !tmdb.status.nil? && !tmdb.status.empty?
          if my_movie.status.nil? || my_movie.status.empty? || my_movie.status != tmdb.status
            my_movie.status = tmdb.status
          end
        end
        if !tmdb.release_date.nil? && !tmdb.release_date.to_date.nil?
          if my_movie.release_date.nil? || my_movie.release_date.to_date.nil? || my_movie.release_date != tmdb.release_date
            my_movie.release_date = tmdb.release_date
          end
        end
        if !tmdb.imdb_id.nil? && !tmdb.imdb_id.empty?
          if my_movie.imdb_id.nil? || my_movie.imdb_id.empty? || my_movie.imdb_id != tmdb.imdb_id
            my_movie.imdb_id = tmdb.imdb_id
          end
        end
        if my_movie.tmdb_id.nil? || my_movie.tmdb_id.to_s.empty?
          my_movie.tmdb_id = tmdb.id
        end
        if !tmdb.title.nil? && !tmdb.title.empty?
          if my_movie.title.nil? || my_movie.title.empty? || my_movie.title != tmdb.title
            my_movie.title = tmdb.title
          end
        end
        if !tmdb.tagline.nil? && !tmdb.tagline.empty?
          if my_movie.tagline.nil? || my_movie.tagline.empty? || my_movie.tagline != tmdb.tagline
            my_movie.tagline = tmdb.tagline
          end
        end
        if !tmdb.runtime.nil? && tmdb.runtime != 0
          if my_movie.runtime.nil? || my_movie.runtime == 0 || my_movie.runtime != tmdb.runtime
            my_movie.runtime = tmdb.runtime
          end
        end
        if !tmdb.overview.nil? && !tmdb.overview.empty?
          if my_movie.plot.nil? || my_movie.plot.empty? || my_movie.plot != tmdb.overview
            my_movie.plot = tmdb.overview
          end
        end
        if !tmdb.release_date.nil? && !tmdb.release_date.to_date.nil?
          if my_movie.year.nil? || my_movie.year == 0 || my_movie.year != tmdb.release_date.to_date.year        
            my_movie.year = tmdb.release_date.to_date.year
          end
        end
        if !tmdb.backdrop_path.nil? && !tmdb.backdrop_path.empty?
          if my_movie.fanart.nil? || my_movie.fanart.empty? || my_movie.fanart != tmdb.backdrop_path
            my_movie.fanart = "http://image.tmdb.org/t/p/original" + tmdb.backdrop_path
          end
        end
        if !tmdb.poster_path.nil? && !tmdb.poster_path.empty?
          if my_movie.poster.nil? || my_movie.poster.empty? || my_movie.poster != tmdb.poster_path
            my_movie.poster = "http://image.tmdb.org/t/p/original" + tmdb.poster_path
          end
        end
                
        tmdb.production_countries.each do |country|
          my_country = Country.find_by_name(country.name)
          if !my_country
            my_country = Country.new
            my_country.name = country.name
            my_country.save
          end
          my_movie.countries << my_country unless !my_movie.countries.find{|item| item[:name] == my_country.name}.nil?
        end

        tmdb.genres.each do |genre|
          my_genre = Genre.find_by_name(genre.name)
          if !my_genre
            my_genre = Genre.new
            my_genre.name = genre.name
            my_genre.save
          end
          my_movie.genres << my_genre unless !my_movie.genres.find{|item| item[:name] == my_genre.name}.nil?
        end

        tmdb.spoken_languages.each do |language|
          my_language = Language.find_by_name(language.iso_639_1)
          if !my_language
            my_language = Language.new
            my_language.name = language.iso_639_1
            my_language.save
          end
          my_movie.languages << my_language unless !my_movie.languages.find{|item| item[:name] == my_language.name}.nil?
        end

        tmdb.production_companies.each do |company|
          my_company = Company.find_by_name(company['name'])
          if !my_company
            my_company = Company.new
            my_company.name = company.name
            my_company.save
          end
          my_movie.companies << my_company unless !my_movie.companies.find{|item| item[:name] == my_company.name}.nil?
        end
        
        keywords = Tmdb::Movie.keywords(my_movie.tmdb_id)
        begin
          keywords.keywords.each do |keyword|
            my_keyword = Keyword.find_by_name(keyword.name)
            if !my_keyword
              my_keyword = Keyword.new
              my_keyword.name = keyword.name
              my_keyword.save
            end
            my_movie.keywords << my_keyword unless !my_movie.keywords.find{|item| item[:name] == my_keyword.name}.nil?
          end
        rescue => e
          logger.error "KEYWORDS ERROR: " + e.to_s + "\n"
          my_movie.missing_data = true
        end
        
        trailers = Tmdb::Movie.trailers(my_movie.tmdb_id)
        begin
          trailers.youtube.each do |trailer|
            if trailer.type == 'Trailer'              
              if my_movie.trailer.nil? || my_movie.trailer.empty? || my_movie.trailer != "http://youtube.com/watch?v=" + trailer.source
                my_movie.trailer = "http://youtube.com/watch?v=" + trailer.source
              end              
            end
          end
        rescue => e
          logger.error "TRAILERS ERROR: " + e.to_s + "\n"
          my_movie.missing_data = true
        end
             
        credits = Tmdb::Movie.credits(my_movie.tmdb_id)
        begin            
          credits.cast.each do |actor|
            my_actor = Actor.find_by_name(actor.name)
            if !my_actor
              my_actor = Actor.new
              my_actor.name = actor.name
              if actor.profile_path
                my_actor.image = 'http://image.tmdb.org/t/p/w300' + actor.profile_path
              end
              my_actor.save
            end
            if my_movie.id
              actor_role = MovieActor.find_by_actor_id_and_movie_id(my_actor.id, my_movie.id)
            end
            if !my_movie.id || !actor_role
              actor_role = MovieActor.new
              actor_role.movie = my_movie
              actor_role.actor = my_actor
            end
            actor_role.role = actor.character
            role = ActiveSupport::Inflector.transliterate(actor.character)
            my_movie.movie_actors << actor_role unless !my_movie.movie_actors.find{|item| item[:actor_id] == actor_role.actor_id && ActiveSupport::Inflector.transliterate(item[:role]) == role }.nil?
          end
                     
          credits.crew.each do |crew|
            if crew.department == 'Directing'
              my_director = Director.find_by_name(crew.name)
              if !my_director
                my_director = Director.new
                my_director.name = crew.name
                if crew.profile_path
                  my_director.image = 'http://image.tmdb.org/t/p/w300' + crew.profile_path
                end
                my_director.save
              end
            my_movie.directors << my_director unless !my_movie.directors.find{|item| item[:name] == my_director.name}.nil?
            elsif crew.department == 'Writing'
              my_writer = Writer.find_by_name(crew.name)
              if !my_writer
                my_writer = Writer.new
                my_writer.name = crew.name
                if crew.profile_path
                  my_writer.image = 'http://image.tmdb.org/t/p/w300' + crew.profile_path
                end
                my_writer.save
              end
              if my_movie.id
                writer_role = MovieWriter.find_by_writer_id_and_movie_id(my_writer.id, my_movie.id)
              end
              if !my_movie.id || !writer_role
                writer_role = MovieWriter.new
                writer_role.movie = my_movie
                writer_role.writer = my_writer
              end
              writer_role.role = crew.job
              my_movie.movie_writers << writer_role unless !my_movie.movie_writers.find{|item| item[:writer_id] == writer_role.writer_id && item[:role] == writer_role.role }.nil?
            end
          end
        rescue => e
          logger.error "CREW ERROR: " + e.to_s + "\n"
          my_movie.missing_data = true
        end        
       
        # check Trakt
        if movie.present?
          begin        
            if my_movie.year.nil? || my_movie.year == 0
              my_movie.year = movie['year']
            end
            if my_movie.trakt_id.nil? || my_movie.trakt_id.empty?
              my_movie.trakt_id = movie['url']
            end
            if my_movie.fanart.nil? || my_movie.fanart.empty?
              if !movie['images'].nil? && !movie['images']['fanart'].nil?
                my_movie.fanart = movie['images']['fanart']
              end
            end          
            if my_movie.trailer.nil? || my_movie.trailer.empty?
              my_movie.trailer = movie['trailer']
            end
            if my_movie.tagline.nil? || my_movie.tagline.empty?
              my_movie.tagline = movie['tagline']
            end
        #else
        #  begin
        #    trakt = Trakt.new
        #    trakt.apikey = Rails.application.secrets.trakt_API
        #    trakt_result = trakt.movie.summary(tmdb_id)
        #    if trakt_result
        #      my_movie.trakt_id = trakt_result.url
        #      if my_movie.fanart.nil? || my_movie.fanart.empty?
        #      my_movie.fanart = trakt_result.images.fanart
        #      end
        #      my_movie.trailer = trakt_result.trailer
        #      if my_movie.year.nil? || my_movie.year == 0
        #        my_movie.year = trakt_result.year
        #      end
        #      if my_movie.tagline.nil? || my_movie.tagline.empty?
        #        my_movie.tagline = trakt_result.tagline
        #      end
        #    end
          rescue => e
            logger.error "TRAKT ERROR: " + e.to_s + "\n"
           # my_movie.missing_data = true
          end
        end
        
        # Check OMDB
        if !my_movie.imdb_id.nil? && !my_movie.imdb_id.empty?
          begin  
            imdb = OMDB.id(my_movie.imdb_id)
            if imdb && imdb.response == 'True'
              if my_movie.rated.nil? || my_movie.rated.empty?
                my_movie.rated = imdb.rated
              end
              if my_movie.poster.nil? || my_movie.poster.empty?
                my_movie.poster = imdb.poster
              end
              if my_movie.runtime.nil? || my_movie.runtime == 0
                my_movie.runtime = imdb.runtime
              end
              if my_movie.plot.nil? || my_movie.plot.empty?
                my_movie.plot = imdb.plot
              end
              if my_movie.title.nil? || my_movie.title.empty?
                my_movie.title = imdb.title
              end
              if my_movie.year.nil? || my_movie.year == 0
                my_movie.year = imdb.year
              end
              if my_movie.release_date.nil?
                my_movie.release_date = imdb.released
              end
              my_movie.imdb_rating = imdb.imdb_rating
              imdb.imdb_votes.gsub!(',','') if imdb.imdb_votes.is_a?(String)
              my_movie.imdb_num_votes = imdb.imdb_votes.to_i
              my_movie.awards = imdb.awards
            else
              my_movie.missing_data = true
            end
          rescue => e
            logger.error "OMDB ERROR: " + e.to_s + "\n"
            my_movie.missing_data = true
          end
        else
          my_movie.missing_data = true
        end          
          
        # save movie  
        logger.info "MY MOVIE: \n"
        logger.info my_movie.to_yaml
        logger.info "\n END \n"
        my_movie.save
      else
        logger.info "MOVIE NOT FOUND: " + e.to_s + "\n"
        return nil
      end
    else #if movie in db
      logger.info "\n ALREADY IN DB NO MISSIG DATA \n"
      if update_imdb
        if !my_movie.imdb_id.nil? && !my_movie.imdb_id.empty?   
          logger.info  "\n GET IMDB:" + my_movie.imdb_id.to_s + " \n"
          imdb = OMDB.id(my_movie.imdb_id)
          if imdb && imdb.response == 'True'
            my_movie.imdb_rating = imdb.imdb_rating
            imdb.imdb_votes.gsub!(',','') if imdb.imdb_votes.is_a?(String)
            my_movie.imdb_num_votes = imdb.imdb_votes.to_i
            my_movie.save
          end
        end        
      end
    end
    
    return my_movie    
  end
  
  def self.toggle_user_movie_watched(user, movie_id)
    if user.present? && movie_id.present?
      user_movie = UserMovie.find_by_user_id_and_movie_id(user.id, movie_id)
      if !user_movie
        user_movie = UserMovie.new
        user_movie.movie_id = movie_id
        user_movie.user = user
      end 
      if user_movie.watched == true
        user_movie.watched = false   
      else      
        user_movie.watched = true
      end      
      
      if user_movie.watched == false && user_movie.collection == false && user_movie.watchlist == false
        user_movie.destroy
        return nil
      else
        user_movie.save
        return user_movie
      end      
    end
  end
  
  def self.user_movie_collected(user, movie_id)
    if user.present? && movie_id.present?
      user_movie = UserMovie.find_by_user_id_and_movie_id(user.id, movie_id)
      if !user_movie
        user_movie = UserMovie.new
        user_movie.movie_id = movie_id
        user_movie.user = user
      end 
      if user_movie.collection == true
        user_movie.collection = false   
      else      
        user_movie.collection = true
      end      
       
      if user_movie.watched == false && user_movie.collection == false && user_movie.watchlist == false
        user_movie.destroy
        return nil
      else
        user_movie.save
        return user_movie
      end      
    end
  end
  
  def self.user_movie_watchlist(user, movie_id)
    if user.present? && movie_id.present?
      user_movie = UserMovie.find_by_user_id_and_movie_id(user.id, movie_id)
      if !user_movie
        user_movie = UserMovie.new
        user_movie.movie_id = movie_id
        user_movie.user = user
      end 
      if user_movie.watchlist == true
        user_movie.watchlist = false   
      else      
        user_movie.watchlist = true
      end      
       
      if user_movie.watched == false && user_movie.collection == false && user_movie.watchlist == false
        user_movie.destroy
        return nil
      else
        user_movie.save
        return user_movie
      end      
    end
  end
    
  def self.create_list(user, name, description, privacy, type, allow_edit, edit_privacy, movie)
    if user.present?
      lists = List.find_by_user_id(user.id)
      list = lists.find { |l| l.name == name }   
      
      if list.nil?
        list = List.new
        list.name = name        
        list.description = description
        list.user = user
        list.privacy = privacy
        list.allow_edit = allow_edit
        list.list_type = type
        list.edit_privacy = edit_privacy
        
        list.movies << movie
        list.save
        return true 
      else
        list_movie = ListMovie.find_by_list_id_and_movie_id(list.id, movie.id)
        if !list_movie
          list.movies << movie
          list.save
          return true 
        end
      end           
    end
  end
  
  def self.add_to_list(user, movie, list)
    if user.present? && movie.present?
      watchlist = List.find_by_user_id_and_watchlist(user.id, true)
      if !watchlist
        watchlist = List.new
        watchlist.name = "Watchlist"        
        watchlist.description = "My Watchlist"
        watchlist.user = user
        watchlist.privacy = "private"
        watchlist.allow_edit = true
        watchlist.watchlist = true
        watchlist.list_type = "watchlist"
        watchlist.edit_privacy = "private"
      end 
      
      list_movie = ListMovie.find_by_list_id_and_movie_id(watchlist.id, movie.id)
      logger.info "LIST MOVIE: " + list_movie.to_yaml  + "\n"
      if !list_movie
        watchlist.movies << movie
        watchlist.save
        return true 
      else        
        list_movie.destroy
        watchlist.save 
        return false
      end        
    end
  end
    
  def self.update_user_movie(user, movie, seen, collected, watchlist)
    if user.present? && movie.present?
      user_movie = UserMovie.find_by_user_id_and_movie_id(user.id, movie.id)
      if !user_movie
        user_movie = UserMovie.new
        user_movie.movie = movie
        user_movie.user = user
      end 
      if !seen.nil?
        if user_movie.watched == false && seen == true 
           user_movie.date_watched = Time.now
        elsif user_movie.watched == true && seen == false
           user_movie.date_watched = nil
        end 
        user_movie.watched = seen               
      end
      if !collected.nil?
        user_movie.collection = collected
      end
      if !watchlist.nil?
        user_movie.watchlist = watchlist
      end
      
      if user_movie.watched == false && user_movie.collection == false && user_movie.watchlist == false
        user_movie.destroy
        return nil
      else
        user_movie.save
        return user_movie
      end      
    end
  end    
    
  def self.user_movie_latest_watched(user, current_user)
    if user.present?
     @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = true ", user.id).references(:user_movies).limit(10).order("user_movies.date_watched DESC")
        
     if !current_user.nil? 
        if current_user.id == user.id
          @movies.each do |movie|
            user_movie = movie.user_movies.first
            if !user_movie.nil? 
              if user_movie.watched == true
                movie.watched = true
              end
              if user_movie.collection == true
                movie.collected = true
              end
              if user_movie.watchlist == true
                movie.watchlist = true
              end
            end
          end
        else
          id_map = @movies.map{|m| m.id}        
          current_user_movies = UserMovie.where(:user_id => current_user.id, :movie_id => id_map)
                
          @movies.each do |movie|
            user_movie = current_user_movies.detect{|m| m.movie_id == movie.id }          
            if !user_movie.nil? 
              if user_movie.watched == true
                movie.watched = true
              end
              if user_movie.collection == true
                movie.collected = true
              end
              if user_movie.watchlist == true
                movie.watchlist = true
              end
            end
          end 
        end      
      end
    end
  end
  
  def self.user_movie_watched(user, current_user, page, page_size)
    if user.present?
     @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = true", user.id).references(:user_movies).page(page).per(page_size) 
          
     if !current_user.nil? 
        if current_user.id == user.id
          @movies.each do |movie|
            user_movie = movie.user_movies.first
            if !user_movie.nil? 
              if user_movie.watched == true
                movie.watched = true
              end
              if user_movie.collection == true
                movie.collected = true
              end
              if user_movie.watchlist == true
                movie.watchlist = true
              end
            end
          end
        else
          id_map = @movies.map{|m| m.id}        
          current_user_movies = UserMovie.where(:user_id => current_user.id, :movie_id => id_map)
                
          @movies.each do |movie|
            user_movie = current_user_movies.detect{|m| m.movie_id == movie.id }          
            if !user_movie.nil? 
              if user_movie.watched == true
                movie.watched = true
              end
              if user_movie.collection == true
                movie.collected = true
              end
              if user_movie.watchlist == true
                movie.watchlist = true
              end
            end
          end 
        end      
      end
    end
  end
  
  def self.search_movie(params, user, current_user, page, page_size, watched, only_collected, watchlist, only_user_movies)
   
    if params.present?
      logger.info params
      
      where = {imdb_num_votes: {gt: 10000}}
      
      if user.present?
        if only_user_movies.present?
          if watched.present? && only_collected.present? && watchlist.present?
            @user_movies = user.user_movies.select { |movie| movie.collection == true || movie.watchlist == true }  
          elsif watched.present? && only_collected.present?
            @user_movies = user.user_movies.select { |movie| movie.collection == true }  
          elsif watched.present? && watchlist.present?
            @user_movies = user.user_movies.select { |movie| movie.watchlist == true }  
          elsif watchlist.present? && only_collected.present?
            @user_movies = user.user_movies.select { |movie| movie.watched == false && (movie.collection == true || movie.watchlist == true)}  
          elsif watched.present?   
            @user_movies = user.user_movies.select { |movie| movie.watched == true }           
          elsif only_collected.present? 
            @user_movies = user.user_movies.select { |movie| movie.watched == false && movie.collection == true } 
          elsif watchlist.present?   
            @user_movies = user.user_movies.select { |movie| movie.watched == false && movie.watchlist == true }  
          else
            @user_movies = user.user_movies.select { |movie| movie.watched == false }   
          end          
          user_movies_id_map = @user_movies.map(&:movie_id)  
          where[:id] = [user_movies_id_map]
        else
          @user_movies = user.user_movies
        end         
      end
      
      search_params = generate_conditions(params, where, search_params)
      
     # print "\n CONDITIONS: " + where.to_s + "\n"
      
      #print "\n search_params: " + search_params.to_s + "\n"
      
      if user.present?
        @movies = Movie.search(search_params, include: [:user_movies], where: where, suggest: true, boost: :imdb_rating, page: page, per_page: page_size)
        
        if !current_user.nil? 
          if current_user.id == user.id
            @movies.each do |movie|
              user_movie = @user_movies.find{|item| item[:movie_id] == movie.id}
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end   
            end    
          else
            id_map = @movies.map{|m| m.id}        
            current_user_movies = UserMovie.where(:user_id => current_user.id, :movie_id => id_map)
                  
            @movies.each do |movie|
              user_movie = current_user_movies.detect{|m| m.movie_id == movie.id }          
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end
            end 
          end      
        end  
      else
        @movies = Movie.search(search_params, where: where, suggest: true, boost: :imdb_rating, page: page, per_page: page_size)
        
        if !current_user.nil?           
          id_map = @movies.map{|m| m.id}        
          current_user_movies = UserMovie.where(:user_id => current_user.id, :movie_id => id_map)
                
          @movies.each do |movie|
            user_movie = current_user_movies.detect{|m| m.movie_id == movie.id }          
            if !user_movie.nil? 
              if user_movie.watched == true
                movie.watched = true
              end
              if user_movie.collection == true
                movie.collected = true
              end
              if user_movie.watchlist == true
                movie.watchlist = true
              end
            end 
          end      
        end  
      end
      
      @suggestion = @movies.suggestions.first
    else #search params not present
      if user.present? && only_user_movies.present?
        if watched.present? && only_collected.present? && watchlist.present?
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND (user_movies.watchlist = true OR user_movies.collection = true)", user.id).references(:user_movies).page(page).per(page_size)
        elsif watched.present? && only_collected.present?
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.collection = true", user.id).references(:user_movies).page(page).per(page_size)    
        elsif watched.present? && watchlist.present?
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watchlist = true", user.id).references(:user_movies).page(page).per(page_size)
        elsif watchlist.present? && only_collected.present?
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = false AND (user_movies.watchlist = true OR user_movies.collection = true)", user.id).references(:user_movies).page(page).per(page_size)
        elsif watched.present?   
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = true", user.id).references(:user_movies).page(page).per(page_size)
        elsif only_collected.present? 
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = false AND user_movies.collection = true", user.id).references(:user_movies).page(page).per(page_size)   
        elsif watchlist.present?   
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = false AND user_movies.watchlist = true", user.id).references(:user_movies).page(page).per(page_size)   
        else
          @movies = Movie.includes(:user_movies).where("user_movies.user_id = ? AND user_movies.watched = false", user.id).references(:user_movies).page(page).per(page_size) 
        end 
        
        if !current_user.nil? 
          if current_user.id == user.id
            @movies.each do |movie|
              user_movie = movie.user_movies.first
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end
            end            
          else
            id_map = @movies.map{|m| m.id}        
            current_user_movies = UserMovie.where(:user_id => current_user.id, :movie_id => id_map)
                  
            @movies.each do |movie|
              user_movie = current_user_movies.detect{|m| m.movie_id == movie.id }          
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end
            end 
          end      
        end   
      else # search trending from trakt 
       # List.update_imdb_top_250
       # List.update_trakt_trending
       # Showtime.udpate_showtimes_slovenia
        list = List.find_by_name_and_list_type('Trending', 'official')
        #logger.info "MOU LISR: " + Movie.first.list_movies.to_yaml
        if list
          @movies = Movie.includes(:list_movies).where("list_movies.list_id = ?", list.id).references(:list_movies).order("list_movies.list_order ASC").page(page).per(page_size)
        end 
        #@movies = List.find_by_name_and_list_type('Trending', 'official').movies.page(page).per(48) 
        if @movies
=begin
        trakt = Trakt.new
        trakt.apikey = Rails.application.secrets.trakt_API
        #trakt = TraktApi::Client.new()        
        #trakt_result = trakt.movies.trending()
        trakt_result = trakt.movie.trending
        if trakt_result
          tmdb_ids = []
          trakt_result.each{|m| tmdb_ids << m.tmdb_id}
          order_hash = {}
          tmdb_ids.each_with_index {|tmdb_id,index | order_hash[tmdb_id]=index}
           
          @movies = Movie.where(:tmdb_id => tmdb_ids)
          @movies = @movies.sort_by { |r| order_hash[r.tmdb_id.to_s] }
=end          
          if current_user.present? 
            @user_movies = UserMovie.where("user_id = ? AND movie_id IN (?)", current_user.id, @movies.map(&:id))
            @movies.each do |movie|
              user_movie = @user_movies.find{|item| item[:movie_id] == movie.id}
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end
            end        
          end          
          #@movies =  Kaminari.paginate_array(@movies).page(page).per(48) 
        else # search popular
          logger.info "SEARCH POPULAR"
          @movies = Movie.search "*", where: {imdb_num_votes: {gt: 150000}}, order: {imdb_rating: :desc, imdb_num_votes: :desc}, page: page, per_page: page_size
          if current_user.present? 
            @user_movies = UserMovie.where("user_id = ? AND movie_id IN (?)", current_user.id, @movies.map(&:id))
            @movies.each do |movie|
              user_movie = @user_movies.find{|item| item[:movie_id] == movie.id}
              if !user_movie.nil? 
                if user_movie.watched == true
                  movie.watched = true
                end
                if user_movie.collection == true
                  movie.collected = true
                end
                if user_movie.watchlist == true
                  movie.watchlist = true
                end
              end
            end        
          end          
        end 
      end
    end    
    return @movies
  end
  
  def self.generate_conditions(params, where, search_params)
    search_params = ""; 
    @genres = Genre.all.map(&:name).map(&:downcase)
    params.each do |str| 
      case
        when @genres.include?(str.downcase)
          where[:genres_name] = str.titleize
        when str.scan(/(^([0-9]|10)([.]\d+)*[+]$)/).flatten.first
          where[:imdb_rating] = {gte: str.to_f}
        when score_down = str.scan(/(^([0-9]|10)([.]\d+)*[-]$)/).flatten.first
          where[:imdb_rating] = {lte: score_down.to_f}
        when score_between = str.scan(/(^([0-9]|10)([.]\d+)*\s*[-]\s*(([0-9]|10)([.]\d+)*))$/).flatten.first
          scores = score_between.split(/\s*[-]\s*/)
          if scores.first.to_f > scores.last.to_f
            where[:imdb_rating] = scores.last.to_f..scores.first.to_f
          else 
            where[:imdb_rating] = scores.first.to_f..scores.last.to_f
          end
        when decade = str.scan(/(^([0-9][0])[']*[s]$)/).flatten.first
          if (decade.to_i < 20)
            year_1 = decade.to_i + 2000
            year_2 = year_1 + 9
          else
            year_1 = decade.to_i + 1900
            year_2 = year_1 + 9
          end
            search_params += str + " "
            where[:or] = [[{keywords_name: decade}, {year: year_1..year_2}]]              
        when year_up = str.scan(/(^(([1][9][0-9][0-9])|([2][0][0-9][0-9])|([0-9][0-9]))[+]$)/).flatten.first
          year = year_up.to_i
          if (year < 100)  
            if (year < 20)
              year += 2000
            else
              year += 1900
            end
          end
          where[:year] = {gte: year}            
        when year_down = str.scan(/(^(([1][9][0-9][0-9])|([2][0][0-9][0-9])|([0-9][0-9]))[-]$)/).flatten.first
          year = year_down.to_i
          if (year < 100)  
            if (year < 20)
              year += 2000
            else
              year += 1900
            end
          end
          where[:year] = {lte: year}
        when year_between = str.scan(/(^(([1][9][0-9][0-9])|([2][0][0-9][0-9])|([0-9][0-9]))\s*[-]\s*(([1][9][0-9][0-9])|([2][0][0-9][0-9])|([0-9][0-9]))$)/).flatten.first
          years = year_between.split(/\s*[-]\s*/)
          year_1 = years.first.to_i
          year_2 = years.last.to_i
          if (year_1 > year_2 && year_2 > 100) 
            year_1 = years.last.to_i
            year_2 = years.first.to_i
          end
          
          if (year_1 < 100)  
            if (year_1 < 20)
              year_1 += 2000
            else
              year_1 += 1900
            end
          end
          if (year_2 < 100)  
            if (year_2 <= 20 || years.first.to_i > year_2)
              year_2 += 2000
            else
              year_2 += 1900
            end
          end
          where[:year] = year_1..year_2
        else
          search_params += str + " "
      end
    end
    
    if search_params.blank?        
      search_params = "*"
    end 
      
    return search_params
  end
end
