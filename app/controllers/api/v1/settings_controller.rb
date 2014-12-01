class Api::V1::SettingsController < ApplicationController
  before_filter :restrict_access  
  respond_to :json
  
  include ActionController::HttpAuthentication::Token
  
  def trakt
     if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "TRAKT"
      
      if params[:trakt_username].present? && params[:trakt_password].present?
        p ":trakt_username : " +params[:trakt_username]  
        @setting = @user.setting       
        @setting.trakt_username = params[:trakt_username]
        @setting.trakt_password = params[:trakt_password]
        
        if @setting.update
          respond_with :response => "OK", :status => 200
        else          
          respond_with :response => @setting.errors, :status => :unprocessable_entity
        end
      else
        render :events => { :info => "Error" }, :status => 403
      end       
    else
      render :events => { :info => "Error" }, :status => 403
    end   
  end

  # GET /movies
  # GET /movies.json
  def index
    if token_and_options(request)
      access_key = AccessKey.find_by_access_token(token_and_options(request))
      @user = User.find_by_id(access_key.user_id)
      
      p "INDEx"
    end
  end
  
  def show
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
  
  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      p "aUTH"
      @token = token
      AccessKey.exists?(access_token: token)
    end
  end
end
