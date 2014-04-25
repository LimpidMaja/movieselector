class SettingsController < ApplicationController
  before_filter :authenticate_user!
  before_filter :correct_user?
  before_action :set_setting, only: [:show, :edit, :update, :destroy]

  @@upload_state = false
  @@upload_percent = 0
  @@upload_movie_count = 0
  # GET /settings
  # GET /settings.json
  def index
    @setting = current_user.setting

    render action: :show
  end

  # GET /settings/1
  # GET /settings/1.json
  def show
    @user = current_user
    @setting = current_user.setting

  end

  # GET /settings/1/edit
  def edit
    @settings = current_user.setting
  end

  # PATCH/PUT /settings/1
  # PATCH/PUT /settings/1.json
  def update
    respond_to do |format|
      if @setting.update(setting_params)
        format.html { redirect_to [@user, @setting], notice: 'Setting was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @setting }
      else
        format.html { render action: 'edit' }
        format.json { render json: @setting.errors, status: :unprocessable_entity }
      end
    end
  end

  def import_trakt
    begin
      @user = User.find_by_username(params[:user_id])
      @setting = @user.setting
      print "\n username:"
      print @setting.trakt_username
      require 'trakt'
      trakt = Trakt.new
      trakt.apikey = Rails.application.secrets.trakt_api
      trakt.username = @setting.trakt_username
      trakt.password = @setting.trakt_password
      print " \n UPLOAD"
      print @@upload_state

      trakt_result = trakt.activity.collection(trakt.username, true)
      trakt_wathed_result = trakt.activity.watched(trakt.username, true)
      #movies_count = trakt_result.each.count

      @@upload_state = true
      @@upload_percent = 0
      @@upload_movie_count = trakt_result.count + trakt_wathed_result.count
      print "\n count\n"
      print @@upload_movie_count
      print "\n"

      json_result = {:upload_state => @@upload_state, :upload_percent => @@upload_percent, :upload_movie_count => @@upload_movie_count}
      #print "\n json: \n"
      #print json_result
      #print " \n"
      render json: json_result.to_json

      Thread.new do
        add_movies(@user, trakt_result, trakt_wathed_result)
      end

    return
    end
  rescue => e
    print "\n error: \n"
    print e
    render json: @setting, status: 500
    # render status: :ok
    # end
    end

  def check_trakt_import_state
    print "\n CHECK STATE \n"
    json_result = {:upload_state => @@upload_state, :upload_percent => @@upload_percent, :upload_movie_count => @@upload_movie_count}
    render json: json_result.to_json
  end

  # DELETE /settings/1
  # DELETE /settings/1.json
  def destroy
    @setting.destroy
    respond_to do |format|
      format.html { redirect_to settings_url }
      format.json { head :no_content }
    end
  end

  private

  def add_movies(user, movies, watched_movies)
    require 'omdbapi'

    count = 0
    requests = 0
    start_time = Time.new

    watched_movies.each do |movie|
      print "\n COUNT: " + count.to_s  + "\n"

      if requests > 26
        seconds = Time.new - start_time
        if seconds < 10
          print "\n SLEEP !!! \n"
          sleep 10
        end
        start_time = Time.new
      requests = 0
      end

      begin
        add_movie(user, movie, true, nil)
      rescue Exception => e
        logger.error "add movie watched failed #{e} COUNT: " + count.to_s + "\n"
      #break
      end
      count += 1
      @@upload_percent = count
      requests += 3
    end

    movies.each do |movie|
      print "\n COUNT: " + count.to_s  + "\n"

      if requests > 26
        seconds = Time.new - start_time
        if seconds < 10
          print "\n SLEEP !!! \n"
          sleep 10
        end
        start_time = Time.new
      requests = 0
      end
      begin
        add_movie(user, movie, nil, true)
      rescue Exception => e
        logger.error "add movie collection failed #{e} COUNT: " + count.to_s + "\n"
      #break
      end
      count += 1
      requests += 3
      @@upload_percent = count
    end

    @@upload_state = false
  rescue => e
    print "\n ERROR ADDING !!!!!!!: \n"
    print e
    print "\n"
    @@upload_state = false
    end

  def add_movie(user, movie, watched, collection)
    if (!movie['imdb_id'].nil? && !movie['imdb_id'].blank?)
      print "\n BY IMDBD:" + movie['imdb_id'].to_s+ " \n"
      my_movie = Movie.find_by_imdb_id(movie['imdb_id'])
    end
    if !my_movie
      print "\n BY TBDM" + movie['tmdb_id'].to_s+ " \n"
      my_movie = Movie.find_by_tmdb_id(movie['tmdb_id'])
    end

    if (!my_movie || my_movie.missing_data == true)
      print "\n GO: \n"
      if !my_movie
        my_movie = Movie.new
        print "\n NEW!!!: \n"
      end
      print "\n MISSING DATAD:" + my_movie.missing_data.to_s+ " \n"
      my_movie.missing_data = false

      if my_movie.imdb_id.nil? || my_movie.imdb_id.empty?
        if !movie['imdb_id'].nil? && !movie['imdb_id'].empty?
          my_movie.imdb_id = movie['imdb_id']
        end
      end
      if my_movie.tmdb_id.nil? || my_movie.tmdb_id.to_s.empty?
        my_movie.tmdb_id = movie['tmdb_id']
      end
      if my_movie.title.nil? || my_movie.title.empty?
        my_movie.title = movie['title']
      end
      if my_movie.year.nil? || my_movie.year == 0
        my_movie.year = movie['year']
      end
      if my_movie.trakt_id.nil? || my_movie.trakt_id.empty?
        my_movie.trakt_id = movie['url']
      end
      if my_movie.fanart.nil? || my_movie.fanart.empty?
        my_movie.fanart = movie['images']['fanart']
      end
      if my_movie.trailer.nil? || my_movie.trailer.empty?
        my_movie.trailer = movie['trailer']
      end
      if my_movie.tagline.nil? || my_movie.tagline.empty?
        my_movie.tagline = movie['tagline']
      end

      genres = movie['genres']
      genres.each do |genre|
        my_genre = Genre.find_by_name(genre)
        if !my_genre
          my_genre = Genre.new
        my_genre.name = genre
        my_genre.save
        end
        my_movie.genres << my_genre unless !my_movie.genres.find{|item| item[:name] == my_genre.name}.nil?
      end

      tmdb = Tmdb::Movie.detail(my_movie.tmdb_id)
      if tmdb && tmdb.id
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

        tmdb.production_countries.each do |country|
          my_country = Country.find_by_name(country.name)
          if !my_country
            my_country = Country.new
          my_country.name = country.name
          my_country.save
          end
          my_movie.countries << my_country unless !my_movie.countries.find{|item| item[:name] == my_country.name}.nil?
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

        tmdb.spoken_languages.each do |language|
          my_language = Language.find_by_name(language.iso_639_1)
          if !my_language
            my_language = Language.new
          my_language.name = language.iso_639_1
          my_language.save
          end
          my_movie.languages << my_language unless !my_movie.languages.find{|item| item[:name] == my_language.name}.nil?
        end

        begin
          keywords = Tmdb::Movie.keywords(my_movie.tmdb_id)
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

        begin
          credits = Tmdb::Movie.credits(my_movie.tmdb_id)
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
        rescue
          my_movie.missing_data = true
        end
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
        my_movie.imdb_num_votes = imdb.imdb_votes
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
    else #if movie in db
      print "\n ALREADY IN DB NO MISSIG DATA \n"
      if !my_movie.imdb_id.nil? && !my_movie.imdb_id.empty?
        print "\n GET IMDB:" + my_movie.imdb_id.to_s + " \n"
        #imdb = OMDB.id(my_movie.imdb_id)
        if imdb && imdb.response == 'True'
          print "\n GET IMDB SUCCESS:" + my_movie.imdb_id.to_s + " \n"
        my_movie.imdb_rating = imdb.imdb_rating
        imdb.imdb_votes.gsub!(',','') if imdb.imdb_votes.is_a?(String)
        my_movie.imdb_num_votes = imdb.imdb_votes.to_i
        my_movie.save
        else
          print "\n IT DOES NOT!!!!"+ " \n"
        end
      else
        print "\n  IMDB_ID NIL!!!!: " + my_movie.imdb_id.to_s + " \n"
      end
    end

    user_movie = UserMovie.find_by_user_id_and_movie_id(user.id, my_movie.id)
    if !user_movie
      user_movie = UserMovie.new
    user_movie.movie = my_movie
    user_movie.user = user
    end
    if watched
    user_movie.watched = watched
    end
    if collection
    user_movie.collection = collection
    else
    user_movie.collection = false
    end
    user_movie.save

  rescue => e
    print "\n ERROR!!!!!!!: \n"
    print e
    if (my_movie)
      logger.error "Unable to get movie #{e}: " + my_movie.to_yaml
    else
      logger.error "Unable to get movie #{e} NULL: "
    end
    print "\n"
    end

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = Setting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def setting_params
    params.require(:setting).permit(:private, :trakt_username, :trakt_password)
  end
end
