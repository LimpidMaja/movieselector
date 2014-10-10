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
    @user = current_user
    @setting = @user.setting

   # @oauth = Koala::Facebook::OAuth.new(Rails.application.secrets.omniauth_provider_key.to_s, Rails.application.secrets.omniauth_provider_secret.to_s, "/auth/facebook/callback")
    #oauth = Koala::Facebook::OAuth.new(Rails.application.secrets.omniauth_provider_key.to_s, Rails.application.secrets.omniauth_provider_secret.to_s, "/auth/:provider/callback_update")
    #new_access_info = oauth.exchange_access_token_info#.auth.credentials.token
    #auth = request.env["omniauth.auth"]
    #  logger.info "\n AUTH!!!\n" + new_access_info.to_yaml + "\n "
   # @oauth.get_user_info_from_cookies(cookies)
   # logger.info "\n AUTH : " + @oauth.to_yaml
   # auth = request.env["omniauth.auth"]
    #logger.info "\n auth!!!!!\n" +auth.to_yaml
    
   # @facebook_cookies ||= Koala::Facebook::OAuth.new(Rails.application.secrets.omniauth_provider_key.to_s, Rails.application.secrets.omniauth_provider_secret.to_s).get_user_info_from_cookie(cookies)
#logger.info "\nFAEBOK COOK: " + @facebook_cookies.to_yaml + "\n"
   #  Movie.sync_facebook(@user) 
  # import_from_facebook
    #@graph = Koala::Facebook::API.new(session[:fb_access_token], Rails.application.secrets.omniauth_provider_secret.to_s)
    #friends = @graph.get_connections("me", "friends")
    #logger.info "\n FRIENDS: " + friends.to_yaml
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
  
  def import_facebook
    @user = current_user
    logger.info "\n HERE!"  + @user.to_yaml
          
    Thread.new do
      Movie.sync_facebook(@user) 
    end
    
    render json: ""
    return     
  end

  def import_trakt
    begin
      @user = current_user
      
      @@upload_state = true
      @@upload_percent = 0
      #@@upload_movie_count = trakt_result.count + trakt_wathed_result.count
      print "\n count\n"
      print @@upload_movie_count
      print "\n"

      json_result = {:upload_state => @@upload_state, :upload_percent => @@upload_percent, :upload_movie_count => @@upload_movie_count}
      #print "\n json: \n"
      #print json_result
      #print " \n"
      render json: json_result.to_json

      Thread.new do
        Movie.sync_trakt(@user) 
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

  # Use callbacks to share common setup or constraints between actions.
  def set_setting
    @setting = Setting.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def setting_params
    params.require(:setting).permit(:private, :trakt_username, :trakt_password)
  end
end
