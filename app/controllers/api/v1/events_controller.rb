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
          all_declined = true
          accepted_count = 0
          
          friends_map ={}          
          event.users.each do |friend_user| 
            friends_map[friend_user.id] = []
            event_user = nil
            
            if event.rating_phase == "wait_users"
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml + "\n"
              if friend_user.id == @user.id && event_user.waiting?
                p "ME - NOT ACCEPT!"
                all_confirmed = false
                event.event_status = "confirm"
                all_declined = false          
              elsif friend_user.id == @user.id && event_user.declined?     
                event.event_status = "declined"            
              elsif event_user.waiting?
                all_declined = false
                all_confirmed = false
              elsif friend_user.id != @user.id && event_user.accepted?
                accepted_count = accepted_count + 1
                all_declined = false
              elsif event_user.accepted?
                accepted_count = accepted_count + 1
              end
            else
              all_declined = false  
            end
            
            if event.rating_phase == "starting"
              if event_user.nil?
                event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              end    
              if event.one_to_five?
                if event_user.accepted? && event_user.num_votes != event.num_votes_per_user
                  if friend_user.id == @user.id 
                    event.event_status = "vote"                    
                  end              
                  all_voted = false                  
                  accepted_count = accepted_count + 1
                elsif event_user.accepted? && event_user.num_votes == event.num_votes_per_user                
                  votes_user_count = votes_user_count + 1
                  votes_count = votes_count + event_user.num_votes                  
                  accepted_count = accepted_count + 1
                end
              elsif event.one_to_ten?
                if event_user.accepted?                  
                  accepted_count = accepted_count + 1
                  event_user_votes = EventUserVote.where("event_id = ? AND user_id = ?", event.id, friend_user.id)
                  if !event_user_votes.nil?
                    score = 0
                    event_user_votes.each do |vote|
                      score = score + vote.score
                    end
                    if score < 2
                      if friend_user.id == @user.id 
                        event.event_status = "vote"                    
                      end                   
                      all_voted = false
                    else
                      votes_user_count = votes_user_count + 1
                    end
                  else 
                    if friend_user.id == @user.id 
                      event.event_status = "vote"                    
                    end                   
                    all_voted = false
                  end  
                end 
              end
            end
                    
            if friend_user.id != @user.id    
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              if event_user.nil?
                event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              end    
              
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                
                  puts "NOT FRIEND: " + friend_user.name + " accept? " + event_user.accept.to_s
              else
                if friend.friend_confirm == true
                  puts "IS FRIEND: " + friend_user.name + " accept? " + event_user.accept.to_s
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  puts "IS REQUEST " + friend_user.name + " accept? " + event_user.accept.to_s
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              event_users << friend_json              
            end
          end
          event.friends = event_users
           
          puts "PHASE: "+ event.id.to_s+ ", "+ event.rating_phase.to_s + " event.finished:" + event.finished.to_s + "system_ " + event.rating_system.to_s
          if event.starting? && event.voting?        
            voting_percent = (votes_user_count * 100) / accepted_count
            print "PERCENT: " + voting_percent.to_s
            if event.one_to_five?
              votes_percent = votes_count * 100 / (accepted_count * event.num_votes_per_user) 
              print "VOTES PERCENT: " + votes_percent.to_s
            end
          end 
          
          seconds_diff = (event.created_at - DateTime.now).to_i.abs
          minutes_diff = seconds_diff / 60
          puts "ITME LIMT : " + event.time_limit.to_s + " m diff: " + minutes_diff.to_s
                      
          if event.finished == true
            event_movie = EventMovie.where("event_id = ? AND winner = true", event.id).limit(1).first
            movie = EventMovie.where("event_id = ? AND winner = true", event.id).limit(1).first    
            event.event_status = "winner" 
            p "WINNER: " + movie.to_yaml + "\n"      
            event.winner_movie = event_movie.movie_id
          elsif all_declined == true            
            event.event_status = "failed"  
          elsif all_confirmed == false && event.event_status != "confirm" && event.event_status != "declined"
            p "WAITING"                        
            
            if minutes_diff > event.time_limit
              if event.user_id == @user.id         
                 puts " TIME LIMIT AFTER "              
                 event.event_status = "start_without_all"
              else
                event.event_status = "waiting_others"                 
              end
            else            
              event.event_status = "waiting_others"
            end
            
          elsif event.voting? && event.starting? && event.event_status != "vote" && all_voted == false && event.minimum_voting_percent < 100 &&
            event.minimum_voting_percent <= voting_percent && ((event.one_to_five? && event.minimum_voting_percent <= votes_percent) || event.one_to_ten?)
            puts " VOTING MINUM<100: " + voting_percent.to_s
            
            if minutes_diff > event.time_limit
              puts " NEXT ROUND ANYWAYS! "  
              
              votingFinished(event, friends_map, @user, true)
              event.time_limit = event.time_limit + 30
              event.save
            else            
              event.event_status = "waiting_others"
            end 
          elsif event.voting? && event.starting? && all_voted == false && event.event_status != "vote"
            if minutes_diff > event.time_limit
              if event.user_id == @user.id               
                event.event_status = "continue_without_all"
              else
                event.event_status = "waiting_others"                 
              end
            else
              p "WAITING"
              event.event_status = "waiting_others"
            end                             
          end
          
          if event.finished == false && event.rating_phase == "knockout_match"
            knockouts =  EventKnockout.where("event_id = ? AND round = ? AND finished = false", event.id, event.knockout_phase).order('id ASC')
            print "knockouts: " + knockouts.to_yaml 
            @knockout_match = []
            knockouts.each do |event_knockout|
              knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", event_knockout.id, @user.id).limit(1).first
              if knockout_user.nil? 
                knockout_json = {id: event_knockout.id, :movie_id_1 => event_knockout.movie_id_1, :movie_id_2 => event_knockout.movie_id_2, :round => knockouts.count}  
                event.knockout_matches = knockout_json
                event.event_status = "knockout_choose"   
                break
              end                      
            end            
                        
            if event.knockout_matches.nil?
              if minutes_diff > event.time_limit
                if event.minimum_voting_percent < 100 && !knockouts.empty?
                  current_knockout = knockouts.first
                  knockout_users_count = KnockoutUser.where("event_knockout_id = ? ", current_knockout.id).count
                  event_user_count = EventUser.where("event_id = ? AND accept = true", event.id).count              
                  voting_percent = (knockout_users_count * 100) / event_user_count
                  if event.minimum_voting_percent <= voting_percent
                    continueKnockout(event, friends_map, @user, true)
                    event.time_limit = event.time_limit + 15
                    event.save
                  else
                    if event.user_id == @user.id               
                      event.event_status = "continue_without_all"
                    else
                      event.event_status = "waiting_others"                 
                    end
                  end
                else  
                  if event.user_id == @user.id               
                    event.event_status = "continue_without_all"
                  else
                    event.event_status = "waiting_others"                 
                  end
                end
              else
                event.event_status = "waiting_others"   
              end
            end                      
          end 
          
          my_event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, @user.id).limit(1).first              
          if my_event_user.declined?                
            event.event_status = "declined"      
          end    

          puts " EVENT " + event.id.to_s + " status: " + event.event_status.to_s           
        else
          @past_events << event 
        end
      end        
          
      respond_with build_events_json(@events)   
    else
      render :events => { :info => "Error" }, :status => 403
    end   
  end

  def votingFinished(event, friends_map, user, send_self)
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
      if event.tie_knockout == true                  
        print "KNOCKOUT"
        
        if !event.knockout_rounds.nil? && event.knockout_rounds != 0
          if @winner.count > (2 ** event.knockout_rounds)
            @winner = @winner.sample(2 ** event.knockout_rounds)
          end
        end                   
                            
        matches = []
        knockouts = []
        while !@winner.empty?            
          round_x = @winner.sample(2)
          matches << round_x
          
          print "ROUND1: " + round_x.to_yaml
          knockout = EventKnockout.new
          knockout.event = event
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
          @winner = @winner.reject { |h| round_x.include? h }              
        end
        @winner = nil
        print "\n\n"
        print "MATCHES: " + matches.to_yaml                     
        
        event.rating_phase = "knockout_match" 
        event.event_status = "knockout_choose"        
        event.knockout_phase = 1
        event.save
                                            
        knockout = knockouts.first                  
        knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
              
        event.knockout_matches = knockout_json
        
        ids = {}
        event.users.each do |friend_user|                        
          event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
          auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
          friend_user.fb_uid = auth.uid          
          
          friends_map.each do |k,array|
            if friend_user.id != k  
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              friends_map[k] << friend_json
            end              
          end
          
          if event_user.accepted?   
            if friend_user.id != user.id || send_self == true          
              access_key = friend_user.access_key
              if access_key && access_key.gcm_reg_id  
                ids[friend_user.id] = friend_user.access_key.gcm_reg_id               
              end  
            end
          end     
        end
        
        # Send invites for Knockout
        ids.each do |k, id| 
          event.friends = friends_map[k]
          gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
          options = { :data => { :title =>"Knockout!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_KNOCKOUT" => true } }
          response = gcm.send([id], options)
          p "RESPONSE: " + response.to_yaml
        end  
        
        event.friends = friends_map[user.id] 
        
        # end knockout
      else
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
          event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
          auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
          friend_user.fb_uid = auth.uid          
          
          friends_map.each do |k,array|
            if friend_user.id != k  
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              friends_map[k] << friend_json
            end              
          end
          
          if event_user.accepted?               
            if friend_user.id != user.id || send_self == true               
              access_key = friend_user.access_key
              if access_key && access_key.gcm_reg_id  
                ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
              end 
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
        
        event.friends = friends_map[user.id] 
      end
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
        event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
        auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
        friend_user.fb_uid = auth.uid          
        
        friends_map.each do |k,array|
          if friend_user.id != k  
            friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              friends_map[k] << friend_json
          end              
        end
        
        if event_user.accepted?               
          if friend_user.id != user.id || send_self == true  
            access_key = friend_user.access_key
            if access_key && access_key.gcm_reg_id  
              ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
            end
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
    
    return event
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
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
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
        all_declined = true  
        friends_map ={}
            
        event_users = []
        
        event.users.each do |friend_user|                      
          friends_map[friend_user.id] = []
          
          event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
          p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml
          
          if friend_user.id == @user.id                        
            if accept == true
              event_user.accept = "accepted"              
              all_declined = false  
              
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
          elsif event_user.accepted?                  
            all_declined = false           
          end     
          
          if friend_user.id != @user.id    
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_user.fb_uid = auth.uid
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
            friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
            if friend.nil?
              friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
            else
              if friend.friend_confirm == true
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
              else
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
              end
            end
            event_users << friend_json              
          end      
        end
                
        event.friends = event_users
        
        puts "eventSYSTEM:" + event.rating_system.to_s
        
        if all_declined == true
          event.event_status = "failed"         
        elsif all_confirmed == true
          if event.voting?
            event.rating_phase = "starting" 
            event.event_status = "vote"        
            event.save
                      
            ids = {}
            event.users.each do |friend_user|  
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid          
              
              friends_map.each do |k,array|
                if friend_user.id != k  
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
                
              if event_user.accepted?  
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
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
          elsif event.knockout?            
            #knockout system
            
            print "KNOCKOUT"
            @winner = event.movies    
            if !event.knockout_rounds.nil? && event.knockout_rounds != 0
              if @winner.count > (2 ** event.knockout_rounds)
                @winner = @winner.sample(2 ** event.knockout_rounds)
              end
            end                   
                                
            matches = []
            knockouts = []
            while !@winner.empty?            
              round_x = @winner.sample(2)
              matches << round_x
              
              print "ROUND1: " + round_x.to_yaml
              knockout = EventKnockout.new
              knockout.event = event
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
              @winner = @winner.reject { |h| round_x.include? h }              
            end
            @winner = nil
            print "\n\n"
            print "MATCHES: " + matches.to_yaml                     
            
            event.rating_phase = "knockout_match" 
            event.event_status = "knockout_choose"        
            event.knockout_phase = 1
            event.save
                                                
            knockout = knockouts.first                  
            knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
                  
            event.knockout_matches = knockout_json
            
            ids = {}
            event.users.each do |friend_user|                        
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid          
              
              friends_map.each do |k,array|
                if friend_user.id != k  
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
                
              if event_user.accepted?  
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
                end       
              end
            end
            
            # Send invites for Knockout
            ids.each do |k, id| 
              event.friends = friends_map[k]
              gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
              options = { :data => { :title =>"Knockout!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_KNOCKOUT" => true } }
              response = gcm.send([id], options)
              p "RESPONSE: " + response.to_yaml
            end  
            
            event.friends = friends_map[@user.id] 
            
            # end knockout
            
          elsif event.random?
            #random movie wins
            winner_movie = event.movies.sample
            event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie.id).limit(1).first    
            event_movie.winner = true
            event_movie.save
            event.finished = true
            event.rating_phase = "done" 
            event.save  
            
            event.event_status = "winner" 
            event.winner_movie = winner_movie.id
            
            ids = {}
            event.users.each do |friend_user|                        
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid          
              
              friends_map.each do |k,array|
                if friend_user.id != k  
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
                
              if event_user.accepted?                
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
                end  
              end     
            end
            
            # Send notification
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
            
      if event.one_to_ten?    
        sum = 0
        params[:rated_movies].each { |vote| sum += vote.score }
        puts "SUM SCORE:"+sum.to_s
      end
         
      if event.rating_phase == "starting" && !params[:rated_movies].nil? && ((event.one_to_five? && params[:rated_movies].count == event.num_votes_per_user) || (event.one_to_ten? && sum > 1)) 
        event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, @user.id).limit(1).first              
               
        if !event_user.nil? && event_user.accepted?
          
          if event.one_to_ten?
            voted = true
            event_user_votes = EventUserVote.where("event_id = ? AND user_id = ?", event.id, @user.id)
            if !event_user_votes.nil?
              score = 0
              event_user_votes.each do |vote|
                score = score + vote.score
              end
              if score < 2                      
                voted = false
              else
                voted = true
              end
            else                  
              voted = false
            end   
          end
            
          if (event.one_to_five? && event_user.num_votes < event.num_votes_per_user) || (event.one_to_ten? && voted == false)
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
            accepted_count = 0
              
            event_users = []
            event.users.each do |friend_user|  
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first 
              if event_user.accepted?
                accepted_count = accepted_count + 1
              end
                           
              if event.one_to_five?
                if event_user.accepted? && event_user.num_votes != event.num_votes_per_user
                  all_voted = false         
                  friends_map[friend_user.id] = []
                elsif event_user.accepted? && event_user.num_votes == event.num_votes_per_user
                  votes_user_count = votes_user_count + 1
                  votes_count = votes_count + event_user.num_votes         
                  friends_map[friend_user.id] = []
                end                
              elsif event.one_to_ten?
                if event_user.accepted?
                  friends_map[friend_user.id] = []
                  event_user_votes = EventUserVote.where("event_id = ? AND user_id = ?", event.id, friend_user.id)
                  if !event_user_votes.nil?
                    score = 0
                    event_user_votes.each do |vote|
                      score = score + vote.score
                    end
                    if score < 2                                        
                      all_voted = false
                    else
                      votes_user_count = votes_user_count + 1
                    end
                  else                                     
                    all_voted = false
                  end  
                end 
              end
                                                
              if friend_user.id != @user.id    
                auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                friend_user.fb_uid = auth.uid
                friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                if friend.nil?
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                else
                  if friend.friend_confirm == true
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                  else
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                  end
                end
                event_users << friend_json              
              end   
            end 
            event.friends = event_users
                        
            voting_percent = (votes_user_count * 100) / accepted_count 
            print "PERCENT: " + voting_percent.to_s
            if event.one_to_five?
              votes_percent = votes_count * 100 / (accepted_count * event.num_votes_per_user) 
              print "VOTES PERCENT: " + votes_percent.to_s
            end
            
            seconds_diff = (event.created_at - DateTime.now).to_i.abs
            minutes_diff = seconds_diff / 60
            puts "ITME LIMT : " + event.time_limit.to_s + " m diff: " + minutes_diff.to_s 
            
            continue_anyways = false
            if (all_voted == false && minutes_diff > event.time_limit && (event.minimum_voting_percent <= voting_percent && 
              ((event.one_to_five? && event.minimum_voting_percent <= votes_percent) || event.one_to_ten?)))
              continue_anyways = true
              event.time_limit = event.time_limit + 30
            end                                                       
              
            if all_voted == true || continue_anyways              
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
                if event.tie_knockout == true                  
                  print "KNOCKOUT"
                  
                  if !event.knockout_rounds.nil? && event.knockout_rounds != 0
                    if @winner.count > (2 ** event.knockout_rounds)
                      @winner = @winner.sample(2 ** event.knockout_rounds)
                    end
                  end                   
                                      
                  matches = []
                  knockouts = []
                  while !@winner.empty?            
                    round_x = @winner.sample(2)
                    matches << round_x
                    
                    print "ROUND1: " + round_x.to_yaml
                    knockout = EventKnockout.new
                    knockout.event = event
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
                    @winner = @winner.reject { |h| round_x.include? h }              
                  end
                  @winner = nil
                  print "\n\n"
                  print "MATCHES: " + matches.to_yaml                     
                  
                  event.rating_phase = "knockout_match" 
                  event.event_status = "knockout_choose"        
                  event.knockout_phase = 1
                  event.save
                                                      
                  knockout = knockouts.first                  
                  knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
                        
                  event.knockout_matches = knockout_json
                  
                  ids = {}
                  event.users.each do |friend_user|                        
                    event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                    auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                    friend_user.fb_uid = auth.uid          
                    
                    friends_map.each do |k,array|
                      if friend_user.id != k  
                        friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                        if friend.nil?
                          friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                        else
                          if friend.friend_confirm == true
                            friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                          else
                            friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                          end
                        end
                        friends_map[k] << friend_json
                      end              
                    end
                    
                    if event_user.accepted?               
                      if friend_user.id != @user.id              
                        access_key = friend_user.access_key
                        if access_key && access_key.gcm_reg_id  
                          ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                        end   
                      end  
                    end     
                  end
                  
                  # Send invites for Knockout
                  ids.each do |k, id| 
                    event.friends = friends_map[k]
                    gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
                    options = { :data => { :title =>"Knockout!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_KNOCKOUT" => true } }
                    response = gcm.send([id], options)
                    p "RESPONSE: " + response.to_yaml
                  end  
                  
                  event.friends = friends_map[@user.id] 
                  
                  # end knockout
                else
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
                    event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                    auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                    friend_user.fb_uid = auth.uid          
                    
                    friends_map.each do |k,array|
                      if friend_user.id != k  
                        friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                        if friend.nil?
                          friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                        else
                          if friend.friend_confirm == true
                            friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                          else
                            friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                          end
                        end
                        friends_map[k] << friend_json
                      end              
                    end
                    
                    if event_user.accepted?               
                      if friend_user.id != @user.id              
                        access_key = friend_user.access_key
                        if access_key && access_key.gcm_reg_id  
                          ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                        end   
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
                  event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                  auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
                  friend_user.fb_uid = auth.uid          
                  
                  friends_map.each do |k,array|
                    if friend_user.id != k  
                      friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                      if friend.nil?
                        friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                      else
                        if friend.friend_confirm == true
                          friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                        else
                          friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                        end
                      end
                      friends_map[k] << friend_json
                    end              
                  end
                  
                  if event_user.accepted?               
                    if friend_user.id != @user.id              
                      access_key = friend_user.access_key
                      if access_key && access_key.gcm_reg_id  
                        ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                      end   
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
            elsif @user.id == event.user_id && minutes_diff > event.time_limit
              event.event_status = "continue_without_all"
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

  def knockout_vote
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      p "EVENT: " + event.to_yaml + "\n"
      p " VOTED: " + params[:movie_id].to_s
      
      if event.rating_phase == "knockout_match" && !params[:movie_id].nil? && !params[:knockout_id].nil?
        event_knockout = EventKnockout.where("event_id = ? AND id = ?", event.id, params[:knockout_id]).limit(1).first
        p " event_knockout " + event_knockout.to_yaml + "\n"
        knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", event_knockout.id, @user.id)
        p " knockout_user " + knockout_user.to_yaml + "\n"
      
        if knockout_user.nil? || knockout_user.empty?          
          p " START " 
          begin
            knockout_user = KnockoutUser.new
            knockout_user.user_id = @user.id
            knockout_user.event_knockout_id = event_knockout.id
            knockout_user.num_votes = 1
            knockout_user.save
                
            event_knockout.num_votes = event_knockout.num_votes + 1
            if params[:movie_id].to_i == event_knockout.movie_id_1
              print "VOTE FOR !1"
              event_knockout.movie_1_score = event_knockout.movie_1_score + 1
            elsif params[:movie_id].to_i == event_knockout.movie_id_2
              print "VOTE FOR !2"
              event_knockout.movie_2_score = event_knockout.movie_2_score + 1
            end            
            event_knockout.save
          end  
            
          all_voted = true
          votes_user_count = 0
          friends_map ={}
          accepted_count = 0
              
          event_users = []
          event.users.each do |friend_user|   
            knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", event_knockout.id, friend_user.id).limit(1).first       
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first   
                       
            if event_user.accepted? && !knockout_user.nil? && knockout_user.num_votes == 1
              votes_user_count = votes_user_count + 1       
              friends_map[friend_user.id] = []
              accepted_count = accepted_count + 1
            elsif event_user.accepted?               
              accepted_count = accepted_count + 1
              all_voted = false                                          
              friends_map[friend_user.id] = []
            end
                                              
            if friend_user.id != @user.id    
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              event_users << friend_json              
            end      
          end 
          event.friends = event_users
                        
          voting_percent = (votes_user_count * 100) / accepted_count
          print "PERCENT: " + voting_percent.to_s
          
          seconds_diff = (event.created_at - DateTime.now).to_i.abs
          minutes_diff = seconds_diff / 60
          puts "ITME LIMT : " + event.time_limit.to_s + " m diff: " + minutes_diff.to_s 
          continue_anyways = false
          if all_voted == false && minutes_diff > event.time_limit && event.minimum_voting_percent <= voting_percent
            continue_anyways = true
            event.time_limit = event.time_limit + 15
          end         
                        
          if all_voted == true || continue_anyways
            print "KNOCKOUT ENDED!" 
            event_knockout.finished = true
            event_knockout.save
            
            knockouts =  EventKnockout.where("event_id = ? AND round = ? ", event.id, event.knockout_phase).order('id ASC')
            print "knockouts: " + knockouts.to_yaml 
            @knockout_match = []
            knockouts.each do |knockout|
              if knockout.finished != true
                @knockout_match << knockout.movie_id_1
                @knockout_match << knockout.movie_id_2
                @knockout_id = knockout.id
                
                knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", knockout.id, @user.id).limit(1).first
                if knockout_user.nil? 
                  knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => knockouts.count}  
                  event.knockout_matches = knockout_json
                  event.event_status = "knockout_choose"
                end
                break
              end
            end
                       
            if @knockout_match.empty?
              if knockouts.count == 1  
                @winner = []       
                knockouts.each do |knockout|
                  if knockout.movie_1_score > knockout.movie_2_score
                    print "WON FIRST"
                    @winner << knockout.movie_id_1               
                  elsif knockout.movie_2_score > knockout.movie_1_score  
                    print "WON SECOND"      
                    @winner << knockout.movie_id_2          
                  else       
                    @winner << knockout.movie_id_1             
                    @winner << knockout.movie_id_2          
                    movie_id = @winner.sample
                    print "WON RANDOM"
                    @winner = []
                    @winner << movie_id
                  end
                end
                       
                winner_movie_id = @winner.first
                event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie_id).limit(1).first    
                event_movie.winner = true
                event_movie.save
                event.finished = true
                event.save  
                event.event_status = "winner" 
                event.winner_movie = winner_movie_id
                                                        
                send_invites(event, friends_map, "winner", false)
                
                event.friends = friends_map[@user.id]              
              else      
                #new knockout phase         
                event.knockout_phase = event.knockout_phase + 1
                event.save
              
                matches = []
                @winner = []
                knockouts.each do |knockout|
                  if knockout.movie_1_score > knockout.movie_2_score 
                    @winner << knockout.movie_id_1              
                  elsif knockout.movie_2_score > knockout.movie_1_score     
                    @winner << knockout.movie_id_2          
                  else
                    temp = []       
                    temp << knockout.movie_id_1       
                    temp << knockout.movie_id_2         
                    movie_id = temp.sample
                    @winner << movie_id
                  end
                end         
                
                print "NEXT ROUND WINNERS: " + @winner.to_yaml     
                
                knockouts = []
                while !@winner.empty?            
                  round_x = @winner.sample(2)
                  matches << round_x
                  
                  print "ROUND1: " + round_x.to_yaml
                  knockout = EventKnockout.new
                  knockout.event = event
                  knockout.movie_id_1 = round_x.first
                  if round_x.count > 1
                    knockout.movie_id_2 = round_x.last
                    knockout.movie_1_score = 0
                    knockout.movie_2_score = 0
                    knockout.round = event.knockout_phase
                    knockout.num_votes = 0
                    knockout.finished = false
                  else
                    knockout.movie_id_2 = 0
                    knockout.movie_1_score = 1
                    knockout.movie_2_score = 0
                    knockout.round = event.knockout_phase                  
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
                
                event.event_status = "knockout_choose"   
                     
                knockout = knockouts.first                  
                knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
                      
                event.knockout_matches = knockout_json
                
                send_invites(event, friends_map, "knockout", false)
                event.friends = friends_map[@user.id]  
              end
            end                        
          else
            knockouts =  EventKnockout.where("event_id = ? AND round = ? ", event.id, event.knockout_phase).order('id ASC')
            print "knockouts: " + knockouts.to_yaml 
            
            found = false
            knockouts.each do |knockout_event|
              if knockout_event.finished != true                
                knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", knockout_event.id, @user.id).limit(1).first
                if knockout_user.nil? 
                  knockout_json = {id: knockout_event.id, :movie_id_1 => knockout_event.movie_id_1, :movie_id_2 => knockout_event.movie_id_2, :round => knockouts.count}  
                  event.knockout_matches = knockout_json
                  event.event_status = "knockout_choose"                  
                  found = true
                  break
                end
              end
            end
            
            if !found
              if @user.id == event.user_id && minutes_diff > event.time_limit
                event.event_status = "continue_without_all"
              else 
                event.event_status = "waiting_others"
              end
            end            
          end
                     
          render json: build_event_json(event), :status => 200, location: @event    
        else
          render json: {:events => { :info => "Already Voted" }}, :status => 405
        end          
      else
        render json: {:events => { :info => "Error" }}, :status => 404
      end 
    else
      render :events => { :info => "Error" }, :status => 403
    end
  end
  
  def cancel
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      if event.user_id == @user.id              
        if event.rating_phase == "wait_users" 
          friends_map ={}   
                     
          event.users.each do |friend_user|                      
            friends_map[friend_user.id] = []
            
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
            p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml
            if friend_user.id != @user.id               
              event_user.accept = "declined"
              event_user.save
            end  
          end
          
          event.event_status = "failed"
                              
          ids = {}
          event.users.each do |friend_user|                        
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_user.fb_uid = auth.uid          
            
            friends_map.each do |k,array|
              if friend_user.id != k  
                friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                if friend.nil?
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                else
                  if friend.friend_confirm == true
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                  else
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                  end
                end
                friends_map[k] << friend_json
              end              
            end
            
            if event_user.accepted?
              if friend_user.id != @user.id              
                access_key = friend_user.access_key
                if access_key && access_key.gcm_reg_id  
                  ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                end   
              end      
            end 
          end
          
          # Send invites
          ids.each do |k, id| 
            event.friends = friends_map[k]
            gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
            options = { :data => { :title =>"Event Cancelled!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_CANCELED" => true } }
            response = gcm.send([id], options)
            p "RESPONSE: " + response.to_yaml
          end  
                    
          event.friends = friends_map[@user.id] 
                    
          render json: build_event_json(event), :status => 200, location: @event    
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
  
  def time_limit
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      if event.user_id == @user.id && params[:time_limit]            
        if event.rating_phase == "wait_users"           
          
          time_limit = params[:time_limit]
             
          event_users = []        
          event.users.each do |friend_user|             
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
                                    
            if friend_user.id != @user.id    
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              
              friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
              if friend.nil?
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
              else
                if friend.friend_confirm == true
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                else
                  friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                end
              end
              event_users << friend_json              
            end      
          end
                  
          event.friends = event_users
          
          p "time_limit:" + time_limit.to_s
          
          event.time_limit = event.time_limit + time_limit
          event.save
          
          event.event_status = "waiting_others"   
          render json: build_event_json(event), :status => 200, location: @event    
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
  
  def start
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])      
      
      if @user.id == event.user_id && event.rating_phase == "wait_users"        
      
        all_confirmed = true  
        all_declined = true  
        friends_map ={}
            
        event_users = []
        
        event.users.each do |friend_user|                      
          friends_map[friend_user.id] = []
          
          event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
          p "EVENT USER:_ " +friend_user.id.to_s + " ACCEPTED:"  +event_user.accept.to_yaml
          
          if friend_user.id != @user.id && event_user.waiting?
            event_user.accept = "declined"
            event_user.save
          elsif friend_user.id != @user.id && event_user.accepted?
            all_declined = false  
          end             
          
          if friend_user.id != @user.id    
            auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
            friend_user.fb_uid = auth.uid
            event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
            friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
            if friend.nil?
              friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
            else
              if friend.friend_confirm == true
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
              else
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
              end
            end
            event_users << friend_json              
          end      
        end
                
        event.friends = event_users
        
        if all_declined == true          
          event.event_status = "failed"  
        elsif all_confirmed == true
          if event.voting?
            event.rating_phase = "starting" 
            event.event_status = "vote"        
            event.save
                      
            ids = {}
            event.users.each do |friend_user|                        
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid          
              
              friends_map.each do |k,array|
                if friend_user.id != k  
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
              
              if event_user.accepted?
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
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
          elsif event.knockout?            
            #knockout system
            
            print "KNOCKOUT"
            @winner = event.movies    
            if !event.knockout_rounds.nil? && event.knockout_rounds != 0
              if @winner.count > (2 ** event.knockout_rounds)
                @winner = @winner.sample(2 ** event.knockout_rounds)
              end
            end                   
                                
            matches = []
            knockouts = []
            while !@winner.empty?            
              round_x = @winner.sample(2)
              matches << round_x
              
              print "ROUND1: " + round_x.to_yaml
              knockout = EventKnockout.new
              knockout.event = event
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
              @winner = @winner.reject { |h| round_x.include? h }              
            end
            @winner = nil
            print "\n\n"
            print "MATCHES: " + matches.to_yaml                     
            
            event.rating_phase = "knockout_match" 
            event.event_status = "knockout_choose"        
            event.knockout_phase = 1
            event.save
                                                
            knockout = knockouts.first                  
            knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
                  
            event.knockout_matches = knockout_json
            
            ids = {}
            event.users.each do |friend_user|                        
              event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
              auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
              friend_user.fb_uid = auth.uid          
              
              friends_map.each do |k,array|
                if friend_user.id != k  
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
              
              if event_user.accepted?
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
                end   
              end    
            end
            
            # Send invites for Knockout
            ids.each do |k, id| 
              event.friends = friends_map[k]
              gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)    
              options = { :data => { :title =>"Knockout!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_KNOCKOUT" => true } }
              response = gcm.send([id], options)
              p "RESPONSE: " + response.to_yaml
            end  
            
            event.friends = friends_map[@user.id] 
            
            # end knockout
            
          elsif event.random?
            #random movie wins
            winner_movie = event.movies.sample
            event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie.id).limit(1).first    
            event_movie.winner = true
            event_movie.save
            event.finished = true
            event.rating_phase = "done" 
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
                  friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
                  if friend.nil?
                    friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
                  else
                    if friend.friend_confirm == true
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
                    else
                      friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
                    end
                  end
                  friends_map[k] << friend_json
                end              
              end
              
              if event_user.accepted?
                if friend_user.id != @user.id              
                  access_key = friend_user.access_key
                  if access_key && access_key.gcm_reg_id  
                    ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
                  end   
                end 
              end      
            end
            
            # Send notification
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
        render json: {:events => { :info => "Error" }}, :status => 404
      end 
    else
      render :events => { :info => "Error" }, :status => 403
    end
  end
 
  def continue
     if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)       
      event = Event.find(params[:id])
      
      if event.user_id == @user.id && event.finished == false
        friends_map ={}
        event.users.each do |friend_user|                      
          friends_map[friend_user.id] = []
        end
        
        if event.starting? && event.voting?
          votingFinished(event, friends_map, @user, false)
          event.time_limit = event.time_limit + 30
          event.save
          render json: build_event_json(event), :status => 200, location: event
        elsif event.knockout_match?
          continueKnockout(event, friends_map, @user, false) 
          event.time_limit = event.time_limit + 15
          event.save
          render json: build_event_json(event), :status => 200, location: event 
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
  
  def continueKnockout(event, friends_map, user, notify_self)
    print "KNOCKOUT ENDED!" 
    knockouts =  EventKnockout.where("event_id = ? AND round = ? AND finished = 0 ", event.id, event.knockout_phase).order('id ASC').limit(1)
    print "knockouts: " + knockouts.to_yaml 
     
    if !knockouts.empty?
      event_knockout = knockouts.first      
      event_knockout.finished = true
      event_knockout.save
      
      knockouts =  EventKnockout.where("event_id = ? AND round = ? ", event.id, event.knockout_phase).order('id ASC')
      print "knockouts: " + knockouts.to_yaml 
      @knockout_match = []
      knockouts.each do |knockout|
        if knockout.finished != true
          @knockout_match << knockout.movie_id_1
          @knockout_match << knockout.movie_id_2
          @knockout_id = knockout.id
          
          knockout_user = KnockoutUser.where("event_knockout_id = ? AND user_id = ? ", knockout.id, @user.id).limit(1).first
          if knockout_user.nil? 
            knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => knockouts.count}  
            event.knockout_matches = knockout_json
            event.event_status = "knockout_choose"
          end
          break
        end
      end
                 
      if @knockout_match.empty?
        if knockouts.count == 1  
          @winner = []       
          knockouts.each do |knockout|
            if knockout.movie_1_score > knockout.movie_2_score
              print "WON FIRST"
              @winner << knockout.movie_id_1               
            elsif knockout.movie_2_score > knockout.movie_1_score  
              print "WON SECOND"      
              @winner << knockout.movie_id_2          
            else       
              @winner << knockout.movie_id_1             
              @winner << knockout.movie_id_2          
              movie_id = @winner.sample
              print "WON RANDOM"
              @winner = []
              @winner << movie_id
            end
          end
                 
          winner_movie_id = @winner.first
          event_movie = EventMovie.where("event_id = ? AND movie_id = ?", event.id, winner_movie_id).limit(1).first    
          event_movie.winner = true
          event_movie.save
          event.finished = true
          event.save  
          event.event_status = "winner" 
          event.winner_movie = winner_movie_id
                                                  
          send_invites(event, friends_map, "winner", true)
          
          event.friends = friends_map[user.id]              
        else      
          #new knockout phase         
          event.knockout_phase = event.knockout_phase + 1
          event.save
        
          matches = []
          @winner = []
          knockouts.each do |knockout|
            if knockout.movie_1_score > knockout.movie_2_score 
              @winner << knockout.movie_id_1              
            elsif knockout.movie_2_score > knockout.movie_1_score     
              @winner << knockout.movie_id_2          
            else
              temp = []       
              temp << knockout.movie_id_1       
              temp << knockout.movie_id_2         
              movie_id = temp.sample
              @winner << movie_id
            end
          end         
          
          print "NEXT ROUND WINNERS: " + @winner.to_yaml     
          
          knockouts = []
          while !@winner.empty?            
            round_x = @winner.sample(2)
            matches << round_x
            
            print "ROUND1: " + round_x.to_yaml
            knockout = EventKnockout.new
            knockout.event = event
            knockout.movie_id_1 = round_x.first
            if round_x.count > 1
              knockout.movie_id_2 = round_x.last
              knockout.movie_1_score = 0
              knockout.movie_2_score = 0
              knockout.round = event.knockout_phase
              knockout.num_votes = 0
              knockout.finished = false
            else
              knockout.movie_id_2 = 0
              knockout.movie_1_score = 1
              knockout.movie_2_score = 0
              knockout.round = event.knockout_phase                  
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
          
          event.event_status = "knockout_choose"   
               
          knockout = knockouts.first                  
          knockout_json = {id: knockout.id, :movie_id_1 => knockout.movie_id_1, :movie_id_2 => knockout.movie_id_2, :round => matches.count}           
                
          event.knockout_matches = knockout_json
          
          send_invites(event, friends_map, "knockout", true)
          event.friends = friends_map[user.id]  
        end
      end
    end
    
    return event
  end
   
  private
    def build_event_json(event)
      event_json = {:event => event.as_json(:include => { :movies => { :only => [:id, :title, :year, :poster ]}}, :methods => [:friends, :knockout_matches, :event_status, :winner_movie])}       
    end
    
    def build_events_json(events)
      events_json = {:events => events.as_json(:include => { :movies => { :only => [:id, :title, :year, :poster ]}}, :methods => [:friends, :knockout_matches, :event_status, :winner_movie])} 
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
    
    def send_invites(event, friends_map, subject, send_self)
      ids = {}
      event.users.each do |friend_user|                        
        event_user = EventUser.where("event_id = ? AND user_id = ?", event.id, friend_user.id).limit(1).first              
        auth = Authorization.find_by_user_id_and_provider(friend_user.id, "facebook")
        friend_user.fb_uid = auth.uid          
        
        friends_map.each do |k,array|
          if friend_user.id != k  
            friend = Friend.where("user_id = ? AND friend_id = ?", friend_user.id, @user.id).limit(1).first              
            if friend.nil?
              friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => false}             
            else
              if friend.friend_confirm == true
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => true, :request => false}           
              else
                friend_json = {id: friend_user.id, :name => friend_user.name, :username => friend_user.username, :fb_uid => auth.uid, :event_accepted => event_user.accept, :confirmed => false, :request => true}           
              end
            end
            friends_map[k] << friend_json
          end              
        end
        
        if  subject == "new_event" || event_user.accepted?         
          if send_self || friend_user.id != @user.id              
            access_key = friend_user.access_key
            if access_key && access_key.gcm_reg_id  
              ids[friend_user.id] = friend_user.access_key.gcm_reg_id  
            end   
          end  
        end     
      end
      
      # Send invites
      ids.each do |k, id| 
        event.friends = friends_map[k]
        gcm = GCM.new(Rails.application.secrets.gcm_api_server_key.to_s)   
        if subject == "winner" 
          options = { :data => { :title =>"We have a Winner!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_WINNER" => true } }
        elsif subject == "knockout" 
          options = { :data => { :title =>"Knockout!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_KNOCKOUT" => true } }            
        elsif subject == "vote" 
          options = { :data => { :title =>"Voting started!", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_EVENT_VOTING" => true } }
        elsif subject == "new_event" 
          options = { :data => { :title =>"New Event", :body => build_event_json(event), :"com.limpidgreen.cinevox.KEY_NEW_EVENT" => true } }
        end
        response = gcm.send([id], options)
        p "RESPONSE: " + response.to_yaml
      end  
    end
end
