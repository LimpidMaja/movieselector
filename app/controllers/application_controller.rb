class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception

  helper_method :current_user
  helper_method :user_signed_in?
  helper_method :correct_user?
  helper_method :correct_user_by_user_id?

  require 'themoviedb'

  before_filter :set_config
  Tmdb::Api.key("853dd1ae90a85ae4cf4e9dd30078596d")

  def set_config
    @configuration = Tmdb::Configuration.new
  end

  private

  def current_user
    begin
      @current_user ||= User.find_by_username(session[:user_id]) if session[:user_id]
    rescue Exception => e
      nil
    end
  end

  def user_signed_in?
    return true if current_user
  end

  def correct_user?
    id = params[:user_id];
    if !id
      id = params[:id]
    end
    @user = User.find_by_username(id)
    unless current_user == @user
      redirect_to root_url, :alert => "Access denied."
    end
  end

  def correct_user_by_user_id?
    @user = User.find_by_username(params[:user_id])
    unless current_user == @user
      redirect_to root_url, :alert => "Access denied."
    end
  end

  def authenticate_user!
    if !current_user
      redirect_to root_url, :alert => 'You need to sign in for access to this page.'
    end
  end

end
