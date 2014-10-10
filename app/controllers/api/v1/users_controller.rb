class Api::V1::UsersController < ApplicationController
  before_filter :restrict_access
  
  respond_to :json

  def index
    respond_with User.all
  end

  def show
    respond_with User.find(params[:id])
  end

  def create
    respond_with User.create(params[:product])
  end

  def update
    respond_with User.update(params[:id], params[:product])
  end

  def destroy
    respond_with User.destroy(params[:id])
  end
  
  private    
  def restrict_access
    authenticate_or_request_with_http_token do |token, options|
      AccessKey.exists?(access_token: token)
    end
  end
end
