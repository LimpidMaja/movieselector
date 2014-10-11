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
          auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
          friend.facebook_id = auth.uid
          friend.picture = "http://graph.facebook.com/" + friend.facebook_id + "/picture" 
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
    print "RAINT rating_phase  " +  @event.voting?.to_s
    p "EVENTS USERS: " + event.users.to_yaml
    p "MOVIES: " + event.movies.to_yaml
    @voting_ended = false
    if @event.finished != true && @event.voting?
      if @event.starting?
        event_users = EventUser.where("event_id = ?", @event.id)
        votes_count = 0
        votes_user_count = 0
        event_users.each do |event_user|
          print "NUM: " + event_user.to_yaml
          if event_user.num_votes > 0 
            votes_user_count = votes_user_count + 1
          end
          votes_count = votes_count + event_user.num_votes
        end
        
        voting_percent = (votes_user_count * 100) / @users.count 
        votes_percent = votes_count * 100 / (@users.count * @event.num_votes_per_user) 
        print "PERCENT: " + voting_percent.to_s
        print "VOTES PERCENT: " + votes_percent.to_s
        
        if @event.minimum_voting_percent <= voting_percent && @event.minimum_voting_percent <= votes_percent
          print "VOTING ENDED!"
          @voting_ended = true
        else
          print "VOTING ACTIVE"
        end
      else
        @voting_ended = true    
      end 
    else
      @voting_ended = true       
    end
      
    highest_score = 0
    highest_score_count = 0
    @winner = []
    @movies.each do |movie|
      user_movie = UserMovie.where("user_id = ? AND movie_id = ?", @user.id, movie.id).limit(1).first    
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
      if @event.finished != true
        event_movie = EventMovie.where("event_id = ? AND movie_id = ?", @event.id, movie.id).limit(1).first    
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
    end  
       print "VOTING ENDED? " + @voting_ended.to_s
       
    if @event.finished == true   
      event_movie = EventMovie.where("event_id = ? AND winner = true", @event.id).limit(1).first 
      @winner << Movie.where("id = ? ", event_movie.movie_id).limit(1).first   
      @voting_ended = true       
    elsif @voting_ended == true
      if highest_score_count > 1 || @event.knockout_match? 
        print "TIE!!"
        
        if @event.tie_knockout == true          
          @knockout = true
          
          if !@event.knockout_match?
            @event.rating_phase = "knockout_match"
            @event.knockout_phase = 1
            @event.save
            
            if @event.knockout_rounds.nil? || @event.knockout_rounds == 0
              matches = []
              knockouts = []
              while !@winner.empty?            
                round_x = @winner.sample(2)
                matches << round_x
                
                print "ROUND1: " + round_x.to_yaml
                knockout = EventKnockout.new
                knockout.event = @event
                knockout.movie_id_1 = round_x.first.id
                if round_x.count > 1
                  knockout.movie_id_2 = round_x.last.id
                  knockout.movie_1_score = 0
                  knockout.movie_2_score = 0
                  knockout.round = 1
                  knockout.num_votes = 0
                  knockout.finished = false
                else
                  knockout.movie_id_2 = 0
                  knockout.movie_1_score = 1
                  knockout.movie_2_score = 0
                  knockout.round = 1                  
                  knockout.num_votes = 1
                  knockout.finished = true
                end                
                knockout.save
                knockouts << knockout
                #print "\n\n"
                @winner = @winner.reject { |h| round_x.include? h }              
              end
              @winner = nil
              print "\n\n"
              print "MATCHES: " + matches.to_yaml     
              @knockout_match = matches.first
              @matches_count = matches.count
              @knockout_id = knockouts.first.id
            else            
            end
          elsif @event.knockout_match?
            knockouts =  EventKnockout.where("event_id = ? AND round = ? ", @event.id, @event.knockout_phase).order('id ASC')
            print "knockouts: " + knockouts.to_yaml 
            @knockout_match = []
            knockouts.each do |event_knockout|
              if event_knockout.finished != true
                movie_1 = @movies.select { |h| event_knockout.movie_id_1 == h['id'] } 
                movie_2 = @movies.select { |h| event_knockout.movie_id_2 == h['id'] } 
                @knockout_match << movie_1.first
                @knockout_match << movie_2.first
                @knockout_id = event_knockout.id
                knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", event_knockout.id, @user.id)
                if knockout_user.nil? || knockout_user.empty?
                  @voted = false
                else
                  @voted = true
                end
                break
              end
            end
            
            if @knockout_match.empty?
              if knockouts.count == 1  
                @winner = []       
                knockouts.each do |event_knockout|
                  if event_knockout.movie_1_score > event_knockout.movie_2_score
                    movie_1 = @movies.select { |h| event_knockout.movie_id_1 == h['id'] } 
                    print "WON FIRST"
                    @winner << movie_1.first               
                  elsif event_knockout.movie_2_score > event_knockout.movie_1_score
                    movie_2 = @movies.select { |h| event_knockout.movie_id_2 == h['id'] }  
                    print "WON SECOND"      
                    @winner << movie_2.first           
                  else
                    movie_1 = @movies.select { |h| event_knockout.movie_id_1 == h['id'] } 
                    movie_2 = @movies.select { |h| event_knockout.movie_id_2 == h['id'] }        
                    @winner << movie_1.first                
                    @winner << movie_2.first           
                    movie = @winner.sample
                    print "WON RANDOM"
                    @winner = []
                    @winner << movie
                  end
                end
                       
                winner_movie = @winner.first
                print "WIINEER IS_ " + winner_movie.to_yaml
                event_movie = EventMovie.where("event_id = ? AND movie_id = ?", @event.id, winner_movie.id).limit(1).first    
                event_movie.winner = true
                event_movie.save                
                @event.finished = true
                @event.save  
                @voting_ended = true    
              else               
                @event.knockout_phase = @event.knockout_phase + 1
                @event.save
              
                matches = []
                @winner = []
                knockouts.each do |event_knockout|
                  if event_knockout.movie_1_score > event_knockout.movie_2_score
                    movie_1 = @movies.select { |h| event_knockout.movie_id_1 == h['id'] } 
                    @winner << movie_1.first               
                  elsif event_knockout.movie_2_score > event_knockout.movie_1_score
                    movie_2 = @movies.select { |h| event_knockout.movie_id_2 == h['id'] }        
                    @winner << movie_2.first           
                  else
                    movie_1 = @movies.select { |h| event_knockout.movie_id_1 == h['id'] } 
                    movie_2 = @movies.select { |h| event_knockout.movie_id_2 == h['id'] } 
                    temp = []       
                    temp << movie_1.first                
                    temp << movie_2.first          
                    movie = temp.sample
                    @winner << movie
                  end
                end         
                
                print "NEXT ROUND WINNERS: " + @winner.to_yaml     
                
                knockouts = []
                while !@winner.empty?            
                  round_x = @winner.sample(2)
                  matches << round_x
                  
                  print "ROUND1: " + round_x.to_yaml
                  knockout = EventKnockout.new
                  knockout.event = @event
                  knockout.movie_id_1 = round_x.first.id
                  if round_x.count > 1
                    knockout.movie_id_2 = round_x.last.id
                    knockout.movie_1_score = 0
                    knockout.movie_2_score = 0
                    knockout.round = @event.knockout_phase
                    knockout.num_votes = 0
                    knockout.finished = false
                  else
                    knockout.movie_id_2 = 0
                    knockout.movie_1_score = 1
                    knockout.movie_2_score = 0
                    knockout.round = @event.knockout_phase                  
                    knockout.num_votes = 1
                    knockout.finished = true
                  end                
                  knockout.save
                  knockouts << knockout
                  #print "\n\n"
                  @winner = @winner.reject { |h| round_x.include? h }              
                end
                @winner = nil
                print "\n\n"
                print "MATCHES: " + matches.to_yaml     
                @knockout_match = matches.first
                @matches_count = matches.count
                @knockout_id = knockouts.first.id
              end
            else            
              print "MATCH: " + @knockout_match.to_yaml 
              @matches_count = knockouts.count
            end
          end
        else
          # random Winner
          winner_movie = @winner.sample
          event_movie = EventMovie.where("event_id = ? AND movie_id = ?", @event.id, winner_movie.id).limit(1).first    
          event_movie.winner = true
          event_movie.save
          @winner = []
          @winner << winner_movie
          @event.finished = true
          @event.save  
          @voting_ended = true
        end
        #print @winner.to_yaml
      else
        print "WINNER!!!"
        @voting_ended = true
       # print @winner.first
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
    @event.rating_phase = "starting"
    @event.rating_system = "voting"
    @event.voting_range = "one_to_five"
    @event.finished = false
    
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
                format.json { render json: @event.errors, status: :unprocessable_entity }
              else
                format.html { render :edit }
                format.json { render json: @event.errors, status: :unprocessable_entity }
              end
            end
            return
          end
          
          event_movie.num_votes = event_movie.num_votes + 1
          event_movie.score = event_movie.score + params[:vote].to_f
          
          event_user.num_votes = event_user.num_votes + 1
          
          event_movie.save
          event_user.save
        end
      end
    elsif !params[:knockout_id].nil?
      print "KNOCKOUT VOTE!"
      event_knockout = EventKnockout.where("event_id = ? AND id = ?", @event.id, params[:knockout_id]).limit(1).first
      knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", event_knockout.id, current_user.id)
      if knockout_user.nil? || knockout_user.empty?
        knockout_user = KnockoutUser.new
        knockout_user.user_id = current_user.id
        knockout_user.event_knockout_id = event_knockout.id
        knockout_user.num_votes = 1
        knockout_user.save
        
        event_knockout.num_votes = event_knockout.num_votes + 1
        print "MOVIE_ID: " +params[:movie_id].to_s
        print "MOVIE_ID k: " +event_knockout.movie_id_1.to_s
        if params[:movie_id].to_i == event_knockout.movie_id_1
          print "VOTE FOR !1"
          event_knockout.movie_1_score = event_knockout.movie_1_score + 1
        elsif params[:movie_id].to_i == event_knockout.movie_id_2
          print "VOTE FOR !2"
          event_knockout.movie_2_score = event_knockout.movie_2_score + 1
        end
        if event_knockout.num_votes == @event.users.count
          print "VOTING FINISHED"
          event_knockout.finished = true
        end
        event_knockout.save
      else
        notice = 'You already voted for that Movie!'            
        respond_to do |format|
          if @event.update(event_params)
            format.html { redirect_to @event, notice: notice }
            format.json { render json: @event.errors, status: :unprocessable_entity }
          else
            format.html { render :edit }
            format.json { render json: @event.errors, status: :unprocessable_entity }
          end
        end
        return
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
