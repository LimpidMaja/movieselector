class GenresController < ApplicationController
  before_action :set_genre, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Genre.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /genres
  # GET /genres.json
  def index
    if params[:query].present?
      @genres = Genre.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @genres.suggestions.first
    else
      @genres = Genre.search "*", page: params[:page], per_page: 50
    end
  end

  # GET /genres/1
  # GET /genres/1.json
  def show
    @movies = @genre.movies.page(params[:page]).per(48) 
  end

  # GET /genres/new
  def new
    @genre = Genre.new
  end

  # GET /genres/1/edit
  def edit
  end

  # POST /genres
  # POST /genres.json
  def create
    @genre = Genre.new(genre_params)

    respond_to do |format|
      if @genre.save
        format.html { redirect_to @genre, notice: 'Genre was successfully created.' }
        format.json { render action: 'show', status: :created, location: @genre }
      else
        format.html { render action: 'new' }
        format.json { render json: @genre.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /genres/1
  # PATCH/PUT /genres/1.json
  def update
    respond_to do |format|
      if @genre.update(genre_params)
        format.html { redirect_to @genre, notice: 'Genre was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @genre }
      else
        format.html { render action: 'edit' }
        format.json { render json: @genre.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /genres/1
  # DELETE /genres/1.json
  def destroy
    @genre.destroy
    respond_to do |format|
      format.html { redirect_to genres_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_genre
    @genre = Genre.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def genre_params
    params.require(:genre).permit(:name)
  end
end
