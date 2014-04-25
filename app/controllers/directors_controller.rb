class DirectorsController < ApplicationController
  before_action :set_director, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Director.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /directors
  # GET /directors.json
  def index
    if params[:query].present?
      @directors = Director.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @directors.suggestions.first
    else
      @directors = Director.search "*", page: params[:page], per_page: 50
    end
  end

  # GET /directors/1
  # GET /directors/1.json
  def show
    @movies = @director.movies
  end

  # GET /directors/new
  def new
    @director = Director.new
  end

  # GET /directors/1/edit
  def edit
  end

  # POST /directors
  # POST /directors.json
  def create
    @director = Director.new(director_params)

    respond_to do |format|
      if @director.save
        format.html { redirect_to @director, notice: 'Director was successfully created.' }
        format.json { render action: 'show', status: :created, location: @director }
      else
        format.html { render action: 'new' }
        format.json { render json: @director.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /directors/1
  # PATCH/PUT /directors/1.json
  def update
    respond_to do |format|
      if @director.update(director_params)
        format.html { redirect_to @director, notice: 'Director was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @director }
      else
        format.html { render action: 'edit' }
        format.json { render json: @director.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /directors/1
  # DELETE /directors/1.json
  def destroy
    @director.destroy
    respond_to do |format|
      format.html { redirect_to directors_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_director
    @director = Director.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def director_params
    params.require(:director).permit(:name, :lastname)
  end
end
