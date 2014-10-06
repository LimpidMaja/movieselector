class ShowtimesController < ApplicationController
  before_action :set_showtime, only: [:show, :edit, :update, :destroy]

  # GET /showtimes
  # GET /showtimes.json
  def index
    @locations = cities = ['Maribor', 'Ljubljana', 'Celje', 'Kranj', 'Koper', 'Novo Mesto', 'Murska Sobota', 'Črnomelj', 'Domžale', 'Izola', 'Krško', 'Metlika', 'Nova Gorica', 'Ptuj',
      'Sežana', 'Slovenj gradec', 'Šmarje pri Jelšah', 'Trbovlje', 'Velenje', 'Zagorje', 'Kamnik', 'Bled', 'Brežice', 'Gornja Radgona', 'Grosuplje',
      'Izlake', 'Jesenice', 'Kočevje', 'Pivka', 'Radovljica', 'Rogaška slatina', 'Sevnica', 'Škofja loka', 'Slovenske konjice', 'Šmarjeske toplice', 'Tolmin', 'Vrhnika', 'Žiri']
    time = Time.now
    @dates = [time.strftime('%d.%m.%Y')]
    6.times do
      @dates << (@dates.last.to_date + 1.day).strftime('%d.%m.%Y')
    end
    if params[:date].present?
      @selected_date = params[:date]
      puts "DATE: " +  params[:date]
    else
      @selected_date = @dates.first.parameterize.underscore
    end
    
    if params[:location]
      @selected_location = params[:location]
    else      
      @user = current_user
      if @user
        @graph = Koala::Facebook::API.new(@user.access_token_fb, Rails.application.secrets.omniauth_provider_secret.to_s)
        profile = @graph.get_object("me")
        if profile && profile.location
          city = profile.location.name.split(',').first.strip 
          if @locations.include?(city)
            @selected_location = city
          end       
        end
      end
      if !@selected_location
        @selected_location = 'Ljubljana'
      end
    end   
    puts "LOCATION: " + @selected_location
    
    @movies = {}
    @showtimes = Showtime.where(city: @selected_location, datetime: @selected_date.to_datetime.midnight..(@selected_date.to_datetime.midnight + 1.day))
    @showtimes.each do |showtime|
      if showtime.movie_id.nil?
        movie = Movie.new
        if showtime.original_title
          movie.title = showtime.original_title
        else
          movie.title = showtime.title
        end
      else
        movie = Movie.find(showtime.movie_id)
      end
      puts "MOVIE: " + movie.to_yaml
      if !@movies[movie]
        @movies[movie] = []
      end
      @movies[movie] << showtime
    end
    puts "MOVIES: " +  @movies.to_yaml
  end

  # GET /showtimes/1
  # GET /showtimes/1.json
  def show
  end

  # GET /showtimes/new
  def new
    @showtime = Showtime.new
  end

  # GET /showtimes/1/edit
  def edit
  end

  # POST /showtimes
  # POST /showtimes.json
  def create
    @showtime = Showtime.new(showtime_params)

    respond_to do |format|
      if @showtime.save
        format.html { redirect_to @showtime, notice: 'Showtime was successfully created.' }
        format.json { render :show, status: :created, location: @showtime }
      else
        format.html { render :new }
        format.json { render json: @showtime.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /showtimes/1
  # PATCH/PUT /showtimes/1.json
  def update
    respond_to do |format|
      if @showtime.update(showtime_params)
        format.html { redirect_to @showtime, notice: 'Showtime was successfully updated.' }
        format.json { render :show, status: :ok, location: @showtime }
      else
        format.html { render :edit }
        format.json { render json: @showtime.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /showtimes/1
  # DELETE /showtimes/1.json
  def destroy
    @showtime.destroy
    respond_to do |format|
      format.html { redirect_to showtimes_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_showtime
      @showtime = Showtime.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def showtime_params
      params.require(:showtime).permit(:movie_id, :title, :original_title, :cinema, :time, :date, :is_3d, :is_synchronized, :city, :country, :state)
    end
end
