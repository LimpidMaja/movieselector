class Api::V1::EventsController < ApplicationController
  before_filter :restrict_access  
  respond_to :json
    
  require 'gcm'  
  include ActionController::HttpAuthentication::Token
    
  # GET /events
  # GET /events.json
  def index
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)     
      p "@user: " + @user.to_yaml
      
      @events = []
      @past_events = []
      user_events = @user.events.includes([:movies, :users])
      user_events.each do |event| 
        if event.event_date >= Date.today
          @events << event
                    
          event_users = []
          all_confirmed = true
          all_voted = true
          votes_count = 0
          votes_user_count = 0
          
          event.users.each do |friend_user| 
            event_user = nil
            if event.rating_phase == "wait_users"
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml + "\n"
              if friend_user.id == @user.id && event_user.waiting?
                p "ME - NOT ACCEPT!"
                all_confirmed = false
                event.event_status = "confirm"                
              elsif event_user.waiting?
                all_confirmed = false
              end
            end
            
            if event.rating_phase == "starting"
              if event_user.nil?
                event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              end    
              if event_user.accepted? && event_user.num_votes != event.num_votes_per_user
                if friend_user.id == @user.id 
                  event.event_status = "vote"                    
                end              
                all_voted = false
              elsif event_user.accepted? && event_user.num_votes == event.num_votes_per_user                
                votes_user_count = votes_user_count + 1
                votes_count = votes_count + event_user.num_votes
              end
            end
                    
            if friend_user.id != @user.id    
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              if event_user.nil?
                event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              end                   
              friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
              event_users << friend_json              
            end
          end
          
          voting_percent = (votes_user_count * 100) / event.users.count 
          votes_percent = votes_count * 100 / (event.users.count * event.num_votes_per_user) 
          print "PERCENT: " + voting_percent.to_s
          print "VOTES PERCENT: " + votes_percent.to_s
            
          #if event.minimum_voting_percent <= voting_percent && event.minimum_voting_percent <= votes_percent
          if event.finished == true
            event_movie = EventMovie.where("event_id = ? AND winner = true", event.id).limit(1).first
            movie = EventMovie.where("event_id = ? AND winner = true", event.id).limit(1).first    
            event.event_status = "winner" 
            p "WINNER: " + movie.to_yaml + "\n"      
            event.winner_movie = event_movie.movie_id
          elsif (all_confirmed == false && event.event_status != "confirm") || (all_voted == false && event.event_status != "vote")
            p "WAITING"
            event.event_status = "waiting_others"   
          elsif all_voted == true && event.minimum_voting_percent <= voting_percent && event.minimum_voting_percent <= votes_percent
            event.event_status = "winner"                     
          end
                   
          event.friends = event_users
        else
          @past_events << event 
        end
      end        
          
      respond_with build_events_json(@events)   
    else
      render :events => { :info => "Error" }, :status => 403
    end   
  end

  # GET /events/1
  # GET /events/1.json
  def show
    
    p "SHOW"
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
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      @event = Event.new(event_params)
      print @event.to_yaml
      
      @event.user_id = @user.id
      @event.rating_phase = "wait_users"
      @event.rating_system = "voting"
      @event.voting_range = "one_to_five"
      @event.finished = false
      
      event_user = EventUser.new
      event_user.user_id = @user.id
      event_user.event = @event
      event_user.num_votes = 0; 
      event_user.accept = "accepted";     
      @event.event_users << event_user
    
    
      friends_map ={}
      friends_map[@user.id] = []
    
      params[:friends].each do |friend_id| 
        event_user = EventUser.new
        event_user.user_id = friend_id
        event_user.event = @event
        event_user.num_votes = 0;
        event_user.accept = "waiting";
        
        friends_map[friend_id] = []
        
        @event.event_users << event_user
      end
          
      params[:movies].each do |movie_id| 
        event_movie = EventMovie.new
        event_movie.movie_id = movie_id
        event_movie.event = @event
        event_movie.num_votes = 0;
        event_movie.score = 0.0;
        
        @event.event_movies << event_movie
      end     
      
      if @event.save        
        
        print @event.to_yaml
        
        ids = {}
        @event.users.each do |friend_user|                        
          auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
          friend_user.fb_uid = auth.uid          
          
          friends_map.each do |k,array|
            if friend_user.id != k  
              event_user = EventUser.where("event_id = ? AND user_id = ?", @event.id, friend_user.id).limit(1).first              
              friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
              friends_map[k] << friend_json
            end              
          end
          
          if friend_user.id != @user.id              
            access_key = friend_user.access_key
            if access_key && access_key.gcm_reg_id  
              ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
            end   
          end       
        end
                    
        # Send invites
        ids.each do |k, id| 
          @event.friends = friends_map[k]
          @event.event_status = "confirm"
          
          #event_json = {:event => @event.as_json(:include => { :movies => { :only => [:id, :title, :year, :poster ]}, :friends => { :only => [:id, :name, :username], :methods => :fb_uid}}, :methods => [:friends, :event_status])}
          gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
          options = { :data => { :title =>"New Event", :body => build_event_json(@event), :"com.limpidgreen.cinevox.KEY_NEW_EVENT" => true } }
          response = gcm.send([id], options)
          p "RESPONSE: " + response.to_yaml
        end                  
           
        @event.friends = friends_map[@user.id] 
        @event.event_status = "waiting_others"
        render json: build_event_json(@event), status: :created, location: @event    
      else
        render json: @event.errors, status: :unprocessable_entity 
      end      
    else
      render :events => { :info => "Error" }, :status => 403
    end 
  end

  # PATCH/PUT /events/1
  # PATCH/PUT /events/1.json
  def update
    p "UPDATE"
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
  
  def confirm
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      @event_user = User.find_by_id(event.user_id)  
      p "EVENT USER_: " + @event_user.to_yaml + "\n"
      
      if event.rating_phase == "wait_users"
        accept = params[:accept]
        
        p "EVENT_: " + event.to_yaml
        p "ACCEPT:" + accept.to_s
                
        all_confirmed = true  
        friends_map ={}
            
        event_users = []
        
        event.users.each do |friend_user|                      
          friends_map[friend_user.id] = []
          
          event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
          p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml
          
          if friend_user.id == @user.id                        
            if accept == true
              event_user.accept = "accepted"
              
              gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
              options = { :data => { :title =>@user.name + " will join your Movie Night!", :friend_id => @user.id, :confirm => true, :event_id => event.id, :event_name => event.name, :"com.limpidgreen.cinevox.KEY_EVENT_FRIEND_CONFIRM" => true } }
              response = gcm.send([@event_user.access_key.gcm_reg_id], options)
              p "RESPONSE: " + response.to_yaml
            
            else              
              event_user.accept = "declined"
              
              gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
              options = { :data => { :title =>@user.name + " has declined your invitation!", :friend_id => @user.id, :confirm => false, :event_id => event.id, :event_name => event.name, :"com.limpidgreen.cinevox.KEY_EVENT_FRIEND_CONFIRM" => true } }
              response = gcm.send([@event_user.access_key.gcm_reg_id], options)
              p "RESPONSE: " + response.to_yaml
            end
            event_user.save
                                    
          elsif event_user.waiting?
            all_confirmed = false              
          end     
          
          if friend_user.id != @user.id    
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_user.fb_uid = auth.uid
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
            friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
            event_users << friend_json              
          end      
        end
                
        event.friends = event_users
        
        if all_confirmed == true
          event.rating_phase = "starting" 
          event.event_status = "vote"        
          event.save
                    
          ids = {}
          event.users.each do |friend_user|                        
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_user.fb_uid = auth.uid          
            
            friends_map.each do |k,array|
              if friend_user.id != k  
                event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
                friends_map[k] << friend_json
              end              
            end
            
            if friend_user.id != @user.id              
              access_key = friend_user.access_key
              if access_key && access_key.gcm_reg_id  
                ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
              end   
            end       
          end
          
          # Send invites
          ids.each do |k, id| 
            event.friends = friends_map[k]
            gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
            options = { :data => { :title =>"Voting started!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_VOTING" => true } }
            response = gcm.send([id], options)
            p "RESPONSE: " + response.to_yaml
          end  
          
          event.friends = friends_map[@user.id] 
        else
          event.event_status = "waiting_others"     
        end  
        
        render json: build_event_json(event), :status => 200, location: @event    
     
      else
        render json: {:events => { :info => "Error" }}, :status => 404
      end 
    else
      render :events => { :info => "Error" }, :status => 403
    end
  end
  
  def vote
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      p "EVENT: " + event.to_yaml + "\n"
      p " RATED: " + params[:rated_movies].to_yaml
      
      if event.rating_phase == "starting" && !params[:rated_movies].nil? && params[:rated_movies].count == event.num_votes_per_user
        event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, @user.id).limit(1).first              
               
        if !event_user.nil? && event_user.accepted?
          if event_user.num_votes < event.num_votes_per_user
            begin
              params[:rated_movies].each do |vote|
                p "MOVIED IF: " + vote.id.to_s
                event_user_vote = EventUserVote.where("event_id = ? AND user_id = ? AND movie_id = ?", event.id, @user.id, vote.id)
                p "EVENT USER " + event_user_vote.to_yaml + "\n"
                if event_user_vote.empty?
                  p "NEW EVENT VOTE: \n" 
                  event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, vote.id).limit(1).first  
                  event_movie.num_votes = event_movie.num_votes + 1
                  event_movie.score = event_movie.score + vote.score
                  event_movie.save
                  
                  event_user_vote = EventUserVote.new
                  event_user_vote.event_id = event.id
                  event_user_vote.user_id = @user.id
                  event_user_vote.movie_id = vote.id
                  event_user_vote.score = vote.score
                  p "EVENT VOTE: " + event_user_vote.to_yaml + "\n"
                  event_user.num_votes = event_user.num_votes + 1
                  event_user_vote.save
                end 
              end
              event_user.save 
              p "EVENT USER " + event_user.to_yaml + "\n"
            end
            
            all_voted = true
            votes_count = 0
            votes_user_count = 0
            friends_map ={}
              
            event_users = []
            event.users.each do |friend_user|              
              friends_map[friend_user.id] = []
          
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              if event_user.accepted? && event_user.num_votes != event.num_votes_per_user
                all_voted = false
              elsif event_user.accepted? && event_user.num_votes == event.num_votes_per_user
                votes_user_count = votes_user_count + 1
                votes_count = votes_count + event_user.num_votes
              end
                                                
              if friend_user.id != @user.id    
                auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                friend_user.fb_uid = auth.uid
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
                event_users << friend_json              
              end      
            end 
            event.friends = event_users
                        
            voting_percent = (votes_user_count * 100) / event.users.count 
            votes_percent = votes_count * 100 / (event.users.count * event.num_votes_per_user) 
            print "PERCENT: " + voting_percent.to_s
            print "VOTES PERCENT: " + votes_percent.to_s
              
            if event.minimum_voting_percent <= voting_percent && event.minimum_voting_percent <= votes_percent
              print "VOTING ENDED!" 
              highest_score = 0
              highest_score_count = 0
              @winner = []
              
              event.movies.each do |movie|
                event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, movie.id).limit(1).first    
                if !event_movie.nil?
                  if event_movie.score != 0
                    movie.voting_score = (event_movie.score / event_movie.num_votes)                   
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
              
              if highest_score_count > 1
                print "TIE!!"
                #if event.tie_knockout == true
                #else
                  # random Winner
                  winner_movie = @winner.sample
                  event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie.id).limit(1).first    
                  event_movie.winner = true
                  event_movie.save
                  event.finished = true
                  event.save  
                  
                  event.event_status = "winner" 
                  event.winner_movie = winner_movie.id
                  
                  ids = {}
                  event.users.each do |friend_user|                        
                    auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                    friend_user.fb_uid = auth.uid          
                    
                    friends_map.each do |k,array|
                      if friend_user.id != k  
                        event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                        friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
                        friends_map[k] << friend_json
                      end              
                    end
                    
                    if friend_user.id != @user.id              
                      access_key = friend_user.access_key
                      if access_key && access_key.gcm_reg_id  
                        ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                      end   
                    end       
                  end
                  
                  # Send invites
                  ids.each do |k, id| 
                    event.friends = friends_map[k]
                    gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
                    options = { :data => { :title =>"We have a Winner!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_WINNER" => true } }
                    response = gcm.send([id], options)
                    p "RESPONSE: " + response.to_yaml
                  end  
                  
                  event.friends = friends_map[@user.id] 
                #end
              else                  
                winner_movie = @winner.first
                event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie.id).limit(1).first    
                event_movie.winner = true
                event_movie.save
                event.finished = true
                event.save  
                event.event_status = "winner" 
                event.winner_movie = winner_movie.id
                
                ids = {}
                event.users.each do |friend_user|                        
                  auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                  friend_user.fb_uid = auth.uid          
                  
                  friends_map.each do |k,array|
                    if friend_user.id != k  
                      event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept}           
                      friends_map[k] << friend_json
                    end              
                  end
                  
                  if friend_user.id != @user.id              
                    access_key = friend_user.access_key
                    if access_key && access_key.gcm_reg_id  
                      ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                    end   
                  end       
                end
                
                # Send invites
                ids.each do |k, id| 
                  event.friends = friends_map[k]
                  gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
                  options = { :data => { :title =>"We have a Winner!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_WINNER" => true } }
                  response = gcm.send([id], options)
                  p "RESPONSE: " + response.to_yaml
                end  
                
                event.friends = friends_map[@user.id] 
              end              
            else
              event.event_status = "waiting_others"
            end
                       
            render json: build_event_json(event), :status => 200, location: @event    
          else
            render json: {:events => { :info => "Already Voted" }}, :status => 403
          end
          
          #render json: build_event_json(event), :status => 200, location: @event   
        else
          render json: {:events => { :info => "Error" }}, :status => 404
        end
      else
        render json: {:events => { :info => "Error" }}, :status => 404
      end 
    else
      render :events => { :info => "Error" }, :status => 403
    end
  end

  private
    def build_event_json(event)
      event_json = {:event => event.as_json(:include => { :movies => { :only => [:id, :title, :year, :poster ]}}, :methods => [:friends, :event_status, :winner_movie])}       
    end
    
    def build_events_json(events)
      events_json = {:events => events.as_json(:include => { :movies => { :only => [:id, :title, :year, :poster ]}}, :methods => [:friends, :event_status, :winner_movie])} 
    end
  
    # Use callbacks to share common setup or constraints between actions.
    def set_event
      @event = Event.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def event_params
      params.require(:event).permit(:name, :description, :event_date, :event_time, :place, :time_limit, :minimum_voting_percent, :users_can_add_movies, :num_add_movies_by_user, :num_votes_per_user, :tie_knockout, :knockout_time_limit, :wait_time_limit, :finished, :knockout_phase, :knockout_rounds, :rating_phase, :rating_system, :voting_range)
    end
        
    def restrict_access
      authenticate_or_request_with_http_token do |token, options|
        p "aUTH"
        @token = token
        AccessKey.exists?(access_token: token)
      end
    end
end
