class WritersController < ApplicationController
  before_action :set_writer, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Writer.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /writers
  # GET /writers.json
  def index
    if params[:query].present?
      @writers = Writer.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @writers.suggestions.first
    else
      @writers = Writer.search "*", page: params[:page], per_page: 50
    end
  end

  # GET /writers/1
  # GET /writers/1.json
  def show
    @movies = @writer.movies.page(params[:page]).per(48) 
  end

  # GET /writers/new
  def new
    @writer = Writer.new
  end

  # GET /writers/1/edit
  def edit
  end

  # POST /writers
  # POST /writers.json
  def create
    @writer = Writer.new(writer_params)

    respond_to do |format|
      if @writer.save
        format.html { redirect_to @writer, notice: 'Writer was successfully created.' }
        format.json { render action: 'show', status: :created, location: @writer }
      else
        format.html { render action: 'new' }
        format.json { render json: @writer.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /writers/1
  # PATCH/PUT /writers/1.json
  def update
    respond_to do |format|
      if @writer.update(writer_params)
        format.html { redirect_to @writer, notice: 'Writer was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @writer }
      else
        format.html { render action: 'edit' }
        format.json { render json: @writer.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /writers/1
  # DELETE /writers/1.json
  def destroy
    @writer.destroy
    respond_to do |format|
      format.html { redirect_to writers_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_writer
    @writer = Writer.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def writer_params
    params.require(:writer).permit(:name, :lastname)
  end
end
