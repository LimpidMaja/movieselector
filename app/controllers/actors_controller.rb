class ActorsController < ApplicationController
  before_action :set_actor, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Actor.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /actors
  # GET /actors.json
  def index
    if params[:query].present?
      @actors = Actor.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @actors.suggestions.first
    else
      @actors = Actor.search "*", page: params[:page], per_page: 50
    end
  end

  # GET /actors/1
  # GET /actors/1.json
  def show
    @movies = @actor.movies.page(params[:page]).per(48) 
  end

  # GET /actors/new
  def new
    @actor = Actor.new
  end

  # GET /actors/1/edit
  def edit
  end

  # POST /actors
  # POST /actors.json
  def create
    @actor = Actor.new(actor_params)

    respond_to do |format|
      if @actor.save
        format.html { redirect_to @actor, notice: 'Actor was successfully created.' }
        format.json { render action: 'show', status: :created, location: @actor }
      else
        format.html { render action: 'new' }
        format.json { render json: @actor.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /actors/1
  # PATCH/PUT /actors/1.json
  def update
    respond_to do |format|
      if @actor.update(actor_params)
        format.html { redirect_to @actor, notice: 'Actor was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @actor }
      else
        format.html { render action: 'edit' }
        format.json { render json: @actor.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /actors/1
  # DELETE /actors/1.json
  def destroy
    @actor.destroy
    respond_to do |format|
      format.html { redirect_to actors_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_actor
    @actor = Actor.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def actor_params
    params.require(:actor).permit(:name, :lastname)
  end
end
