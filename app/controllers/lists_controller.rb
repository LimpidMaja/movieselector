class ListsController < ApplicationController
  before_action :set_list, only: [:show, :edit, :update, :destroy]
  # GET /lists
  # GET /lists.json
  def index
    #List.update_imdb_top_250
    if params[:user_id]
      authenticate_user!
      correct_user_by_user_id?
      @user = current_user
      @lists = current_user.lists
    else
      if !params[:search]
        @lists = List.all

        puts @lists[0].movies.to_yaml

      else
        @lists = []

        require 'google_search'
        require 'rubygems'
        require 'nokogiri'
        require 'open-uri'

        keyword = params[:search]

        imdb_id_list = {}

        i = 1
        #GoogleSearch.with_pages(1..2) do |search|
        results = GoogleSearch.web :q => keyword + " site:imdb.com/list"
        results.responseData.results.each do |result|
          url = result.url
          puts url
          puts result.titleNoFormatting

          imdb_id_list[result.titleNoFormatting] = []

          list = List.new()
          list.name = result.titleNoFormatting
          list.movies = []
          list.list_movies = []
          
          puts " "

          doc = Nokogiri::HTML(open(url))

          news_links = doc.css("div").select{|link| link['class'] == "info"}
          c = 1
          news_links.each do |info|
            puts "NEW: " + i.to_s

            links = info.css("a")
            links.each do |link|
              if link.to_s.include? "onclick"
                puts link["href"]
                title = link["href"].split('/')[2]
                puts title
                imdb_id_list[result.titleNoFormatting] << title

                movie = Movie.find_by_imdb_id(title)
                
                if movie
                  puts "Movie:"
                  puts movie
                  list_movie = ListMovie.new()
                  list_movie.movie = movie
                  list_movie.list_order = c
                  list.list_movies << list_movie
                  #puts "LM: " + list_movie.to_yaml
                  c = c + 1
                  break;
                end
              end
            end

            puts " "

            i = i + 1
          end
          
          
          if list.list_movies.size > 0
            @lists << list
          end
        end

        puts imdb_id_list
        #puts @lists[0].movies.to_yaml
        @lists.each do |list|  
          puts "NAME: " + list.name        
          puts " TITLES: "
          puts "COUNT: " + list.list_movies.size.to_s
          #puts list.list_movies[0].movie.to_yaml
          list.list_movies.each do |list_movie|
            puts "M: " +  list_movie.movie.to_yaml
          end
        end
          
      end
    end
  end

  # GET /lists/1
  # GET /lists/1.json
  def show

    @movies = Movie.includes(:list_movies).where("list_movies.list_id = ?", @list.id).references(:list_movies).order("list_movies.list_order ASC").page(params[:page]).per(48)
  #@movies = @list.movies.page(params[:page]).per(48)
  end

  # GET /lists/new
  def new
    @list = List.new
  end

  # GET /lists/1/edit
  def edit
  end

  # POST /lists
  # POST /lists.json
  def create
    @list = List.new(list_params)

    respond_to do |format|
      if @list.save
        format.html { redirect_to @list, notice: 'List was successfully created.' }
        format.json { render :show, status: :created, location: @list }
      else
        format.html { render :new }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /lists/1
  # PATCH/PUT /lists/1.json
  def update
    respond_to do |format|
      if @list.update(list_params)
        format.html { redirect_to @list, notice: 'List was successfully updated.' }
        format.json { render :show, status: :ok, location: @list }
      else
        format.html { render :edit }
        format.json { render json: @list.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /lists/1
  # DELETE /lists/1.json
  def destroy
    @list.destroy
    respond_to do |format|
      format.html { redirect_to lists_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_list
    @list = List.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def list_params
    params.require(:list).permit(:name, :description, :type, :privacy, :allow_edit, :rating, :votes_count, :user_id)
  end
end
