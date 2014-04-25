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
      @movies = User.find_by_username(params[:user_id]).movies
    else
     # @movies = Movie.search "*", where: {imdb_num_votes: {gt: 30000}}, order: {imdb_rating: :desc, imdb_num_votes: :desc}, limit: 20, offset: 0

      if params[:query].present?
        @movies = Movie.search(params[:query], suggest: true, page: params[:page], per_page: 50)
        @suggestion = @movies.suggestions.first
      else
    #    trakt = Trakt.new
    #    trakt.apikey = Rails.application.secrets.trakt_api
        
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
        @movies = Movie.all        
      end
    end
=begin    
    @movies.each do |my_movie|
      next if my_movie.id < 43000
      if !my_movie.imdb_id.nil? && !my_movie.imdb_id.empty?
        print "\n GET MOVIE ID" + my_movie.id.to_s + " \n"
        imdb = OMDB.id(my_movie.imdb_id)
        if imdb && imdb.response == 'True'
          begin
            #print "\n GET IMDB SUCCESS:" +imdb.to_yaml + " \n"         
            my_movie.imdb_rating = imdb.imdb_rating
            
            imdb.imdb_votes.gsub!(',','') if imdb.imdb_votes.is_a?(String)
            print "\n GET IMDB VOTES:" + imdb.imdb_votes.to_s + " \n"    
            my_movie.imdb_num_votes = imdb.imdb_votes.to_i
            #break
            my_movie.save
          rescue => e
            print "\n ERROR: " + e + "\n"
            my_movie.missing_data = true
            my_movie.save
            break
          end
        else
          my_movie.missing_data = true
          my_movie.save
        end
      else
        my_movie.missing_data = true
        my_movie.save
      end
    end
=end
    #263698
    # tmdb = Tmdb::Movie.detail(149870)
    # if tmdb.id
    #  print "\nit is:\n"
    #  print tmdb.to_yaml

    #  print "YEAR: " + tmdb.release_date.to_date.year.to_s + "\n"
    #end

    #   tmdb.production_companies.each do |company|
    #       my_company = Company.find_by_name(company.name)
    #       if !my_company
    #         my_company = Company.new
    #         my_company.name = company.name
    #         my_company.save
    #       end
    #my_movie.companies << my_company
    #    end

    #trakt.username = @setting.trakt_username
    #trakt.password = @setting.trakt_password
    #trakt_result = trakt.movie.summary(197962)
    #print trakt_result.to_yaml
    #my_movie = Movie.new
    #     my_movie.trakt_id = trakt_result.url
    #    my_movie.fanart = trakt_result.images.fanart
    #   my_movie.trailer = trakt_result.trailer
    #  print my_movie.to_yaml
  
#=begin
    trakt = Trakt.new
    trakt.apikey = Rails.application.secrets.trakt_api
    count = 0
    requests = 0
    start_time = Time.new
    (265275..270000).each do |i|
    #(149870..149871).each do |i|
      print "\n COUNT: " + count.to_s  + "\n"
      print "\n it is I: " + i.to_s + "\n"

      my_movie = Movie.find_by_tmdb_id(i)
      if !my_movie || my_movie.missing_data == true

        if requests > 26
          seconds = Time.new - start_time
          if seconds < 10
            print "\n SLEEP !!! \n"
            sleep 10
          end
          start_time = Time.new
        requests = 0
        end

        tmdb = Tmdb::Movie.detail(i)
        requests += 1
        if tmdb && tmdb.id && tmdb.adult == false

          # print tmdb.to_yaml
          print "\n GO  \n"
          if !my_movie
            my_movie = Movie.new
            print "\n NEW!!!: \n"
          end

          if my_movie.original_title.nil? || my_movie.original_title.empty?
          my_movie.original_title = tmdb.original_title
          end
          if my_movie.budget.nil? || my_movie.budget.to_s.empty?
          my_movie.budget = tmdb.budget
          end
          if my_movie.revenue.nil? || my_movie.revenue.to_s.empty?
          my_movie.revenue = tmdb.revenue
          end
          if my_movie.status.nil? || my_movie.status.empty?
          my_movie.status = tmdb.status
          end
          if my_movie.release_date.nil?
          my_movie.release_date = tmdb.release_date
          end
          if my_movie.imdb_id.nil? || my_movie.imdb_id.empty?
            if !tmdb.imdb_id.nil? && !tmdb.imdb_id.empty?
            my_movie.imdb_id = tmdb.imdb_id
            end
          end
          if my_movie.tmdb_id.nil? || my_movie.tmdb_id.to_s.empty?
          my_movie.tmdb_id = tmdb.id
          end
          if my_movie.title.nil? || my_movie.title.empty?
          my_movie.title = tmdb.title
          end
          if my_movie.tagline.nil? || my_movie.tagline.empty?
          my_movie.tagline = tmdb.tagline
          end
          if my_movie.runtime.nil? || my_movie.runtime == 0
          my_movie.runtime = tmdb.runtime
          end
          if my_movie.plot.nil? || my_movie.plot.empty?
          my_movie.plot = tmdb.overview
          end
          if my_movie.year.nil? || my_movie.year == 0
            if !tmdb.release_date.nil? && !tmdb.release_date.to_date.nil?
            my_movie.year = tmdb.release_date.to_date.year
            end
          end

          my_movie.missing_data = false

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
            my_company = Company.find_by_name(company.name)
            if !my_company
              my_company = Company.new
            my_company.name = company.name
            my_company.save
            end
            my_movie.companies << my_company unless !my_movie.companies.find{|item| item[:name] == my_company.name}.nil?
          end

          requests += 1
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
          rescue
          my_movie.missing_data = true
          end

          requests += 1
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
              #my_movie.missing_data = true
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
            print "ERROR: " + e.to_s + "\n"
            my_movie.missing_data = true
          end

          begin
            trakt_result = trakt.movie.summary(i)
            if trakt_result
            my_movie.trakt_id = trakt_result.url
            my_movie.fanart = trakt_result.images.fanart
            my_movie.trailer = trakt_result.trailer
            end
          rescue
          my_movie.missing_data = true
          end

          if !my_movie.imdb_id.nil? && !my_movie.imdb_id.empty?
            print "\n GET IMDB:" + my_movie.imdb_id.to_s + " \n"
            imdb = OMDB.id(my_movie.imdb_id)
            if imdb && imdb.response == 'True'
              print "\n GET IMDB SUCCESS:" + my_movie.imdb_id.to_s + " \n"
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
          else
          my_movie.missing_data = true
          end

          print "\n MY MOVIE \n"
          print my_movie.to_yaml
          print "\n END \n"
          
          my_movie.save
        count += 1
        end
      end
    end
#=end
  #rescue => e
  #   print "\n ERROR!!!!!!!!!!!!!!!: \n"
  #  print e
  #  if (my_movie)
  #    logger.error count.to_s + ":Unable to get movie #{e}: " + my_movie.to_yaml
  #  else
  #   logger.error count.to_s + ":Unable to get movie #{e} NULL: "
  # end
  # print "\n"
  end

  # GET /movies/1
  # GET /movies/1.json
  def show
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
