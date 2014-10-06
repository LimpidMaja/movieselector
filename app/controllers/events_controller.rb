class EventsController < ApplicationController
  before_action :set_event, only: [:show, :edit, :update, :destroy]

  def autocomplete_friends  
    @user = current_user
    #print @user.friends.users.to_yaml
    
    @hash = []
    
    @friends = @user.friends
    @friends.each do |friend|
      if friend.friend_confirm == true
        friend_user = User.find_by_id(friend.friend_id)
        puts friend_user.name
        #if friend_user.name =~ /^ma/
        #if friend_user.name.include?(params[:term]) 
          friend.name = friend_user.name
          friend.facebook_id = friend_user.uid
          friend.picture = "http://graph.facebook.com/" + friend_user.uid + "/picture" 
          friend.friend_user_id = friend_user.id  
          
        #puts "ADD " + friend_user.name
          @hash << {"value" => friend_user.name, "id" => friend_user.id}           
       # end
      end
    end
    render :json => @hash
  end
  
  def autocomplete_movies_events
    @user = current_user
    #print @user.friends.users.to_yaml
    
    @hash = []
    @movies= Movie.select("id, title, year").where("title LIKE ?", "#{params[:term]}%").limit(20)
    @movies.each do |movie|
      @hash << { "id" => movie.id, "title" => movie.title, "value" => (movie.title + " (" + movie.year.to_s + ")")}
    end
    print @hash.to_yaml
    render :json => @hash
  end
  
  
  # GET /events
  # GET /events.json
  def index
    @user = current_user
    @events = []
    @past_events = []
    user_events = current_user.events
    user_events.each do |event| 
      if event.event_date >= Date.today
        @events << event
      else
        @past_events << event 
      end
    end
    
    @my_events = Event.where("user_id = ?", @user.id)
  end

  # GET /events/1
  # GET /events/1.json
  def show
    @movies = @event.movies
   # print "MO: " + @movies.to_yaml
    
    @user = current_user     
    @users = @event.users
    
    @voting_ended = false
    event_movies = EventMovie.where("event_id = ?", @event.id)
    votes_count = 0
    event_movies.each do |event_movie|
    print "NUM: " + event_movie.to_yaml
      votes_count = votes_count + event_movie.num_votes
    end
    print "NUM: " + votes_count.to_s
    if @event.minimum_voting_percent == 100 && (@users.count * @event.num_votes_per_user) == votes_count
      print "VOTING ENDED!"
    @voting_ended = true
    else
      print "VOTING ACTIVE"
    end
     
    highest_score = 0
    highest_score_count = 0
    @winner = []
    @movies.each do |movie|
      user_movie = UserMovie.where("user_id = ? AND movie_id = ?", @user.id, movie.id).limit(1).first    
      event_movie = EventMovie.where("event_id = ? AND movie_id = ?", @event.id, movie.id).limit(1).first    
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
      if !event_movie.nil?
        if event_movie.score != 0
          movie.voting_score = (event_movie.score / event_movie.num_votes)
          if @voting_ended == true
            if movie.voting_score > highest_score
              highest_score = movie.voting_score
              highest_score_count = 1
              @winner = []
              @winner << movie
            elsif movie.voting_score == highest_score
              highest_score_count = highest_score_count + 1
              @winner << movie
            end
          end
        end
      end
    end  
       
       
    if @voting_ended == true
      if highest_score_count > 1 
        print "TIE!!"
        print @winner.to_yaml
      else
        print "WINNER!!!"
        print @winner.first
      end    
    end   
  end

  # GET /events/new
  def new
    @event = Event.new
    
  end

  # GET /events/1/edit
  def edit
   
  end

  # POST /events
  # POST /events.json
  def create
    @event = Event.new(event_params)

    print @event.to_yaml
    
    @event.user_id = current_user.id
    
    friend_ids = params[:users].split(",")
    friend_ids.each do |friend_id| 
      event_user = EventUser.new
      event_user.user_id = friend_id
      event_user.event = @event
      event_user.num_votes = 0;
      
      @event.event_users << event_user
    end
    
    event_user = EventUser.new
    event_user.user_id = current_user.id
    event_user.event = @event
    event_user.num_votes = 0;
      
    @event.event_users << event_user
      
    movie_ids = params[:movies].split(",")
    movie_ids.each do |movie_id| 
      event_movie = EventMovie.new
      event_movie.movie_id = movie_id
      event_movie.event = @event
      event_movie.num_votes = 0;
      event_movie.score = 0.0;
      
      @event.event_movies << event_movie
    end
    
    respond_to do |format|
      if @event.save
        format.html { redirect_to @event, notice: 'Event was successfully created.' }
        format.json { render :show, status: :created, location: @event }
      else
        format.html { render :new }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    if !params[:vote].nil?
      print "VOTE!!"

      event_movie = EventMovie.where("event_id = ? AND movie_id = ?", @event.id, params[:movie_id]).limit(1).first  
      if !event_movie.nil? 
        event_user = EventUser.where("user_id = ? AND event_id = ?", params[:user_voted_id], @event.id).limit(1).first   
        if !event_user.nil?
          if event_user.num_votes >= @event.num_votes_per_user
            notice = 'You can not vote more than ' +  @event.num_votes_per_user.to_s + ' times!'
            
            respond_to do |format|
              if @event.update(event_params)
                format.html { redirect_to @event, notice: notice }
                format.json { render :show, status: :ok, location: @event }
              else
                format.html { render :edit }
                format.json { render json: @event.errors, status: :unprocessable_entity }
              end
            end
            return
          end
          
          print "HEEEE: " + event_user.to_yaml 
          event_movie.num_votes = event_movie.num_votes + 1
          event_movie.score = event_movie.score + params[:vote].to_f
          
          event_user.num_votes = event_user.num_votes + 1
          
          event_movie.save
          event_user.save
        end
      end
    end
    
    respond_to do |format|
      if @event.update(event_params)
        format.html { redirect_to @event, notice: 'Event was successfully updated.' }
        format.json { render :show, status: :ok, location: @event }
      else
        format.html { render :edit }
        format.json { render json: @event.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /events/1
  # DELETE /events/1.json
  def destroy
    @event.destroy
    respond_to do |format|
      format.html { redirect_to events_url }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:name, :description, :event_date, :event_time, :place, :time_limit, :minimum_voting_percent, :users_can_add_movies, :num_add_movies_by_user, :num_votes_per_user, :tie_knockout, :knockout_time_limit, :wait_time_limit)
    end
end
