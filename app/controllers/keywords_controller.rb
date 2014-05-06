class KeywordsController < ApplicationController
  before_action :set_keyword, only: [:show, :edit, :update, :destroy]
  def autocomplete
    render json: Keyword.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /keywords
  # GET /keywords.json
  def index
    if params[:query].present?
      @keywords = Keyword.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @keywords.suggestions.first
    else
      @keywords = Keyword.search "*", page: params[:page], per_page: 50
    end
  end

  # GET /keywords/1
  # GET /keywords/1.json
  def show
    @movies = @keyword.movies.page(params[:page]).per(48) 
  end

  # GET /keywords/new
  def new
    @keyword = Keyword.new
  end

  # GET /keywords/1/edit
  def edit
  end

  # POST /keywords
  # POST /keywords.json
  def create
    @keyword = Keyword.new(keyword_params)

    respond_to do |format|
      if @keyword.save
        format.html { redirect_to @keyword, notice: 'Keyword was successfully created.' }
        format.json { render action: 'show', status: :created, location: @keyword }
      else
        format.html { render action: 'new' }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /keywords/1
  # PATCH/PUT /keywords/1.json
  def update
    respond_to do |format|
      if @keyword.update(keyword_params)
        format.html { redirect_to @keyword, notice: 'Keyword was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @keyword }
      else
        format.html { render action: 'edit' }
        format.json { render json: @keyword.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /keywords/1
  # DELETE /keywords/1.json
  def destroy
    @keyword.destroy
    respond_to do |format|
      format.html { redirect_to keywords_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_keyword
    @keyword = Keyword.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def keyword_params
    params.require(:keyword).permit(:name)
  end
end
