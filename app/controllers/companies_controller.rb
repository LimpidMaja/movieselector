# encoding: utf-8
class CompaniesController < ApplicationController
  before_action :set_company, only: [:show, :edit, :update, :destroy]
  
  def autocomplete
    print "\n QUERY: " + params[:query].to_s + "\n"
   # render json: Company.search(params[:query], autocomplete: true, limit: 10).map(&:name)
    
    render json: Company.search(params[:query], fields: [{name: :word_start}], misspellings: {distance: 2}, limit: 10).map(&:name)
  end

  # GET /companies
  # GET /companies.json
  def index
       #@companies =Company.search "das", fields: [{name: :text_start}]
    if params[:query].present?
      @companies = Company.search(params[:query], suggest: true, page: params[:page], per_page: 50)
      @suggestion = @companies.suggestions.first
      print @companies.suggestions.to_yaml
    else
      @companies = Company.search "*", page: params[:page], per_page: 50
    end
  # @companies = Company.order(:name).page params[:page]
  #User.order(:name).page params[:page]
  end

  # GET /companies/1
  # GET /companies/1.json
  def show
    #@company = Company.find_by_name(params[:id])
    @movies = @company.movies
  end

  # GET /companies/new
  def new
    @company = Company.new
  end

  # GET /companies/1/edit
  def edit
  end

  # POST /companies
  # POST /companies.json
  def create
    @company = Company.new(company_params)

    respond_to do |format|
      if @company.save
        format.html { redirect_to @company, notice: 'Company was successfully created.' }
        format.json { render action: 'show', status: :created, location: @company }
      else
        format.html { render action: 'new' }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /companies/1
  # PATCH/PUT /companies/1.json
  def update
    respond_to do |format|
      if @company.update(company_params)
        format.html { redirect_to @company, notice: 'Company was successfully updated.' }
        format.json { render action: 'show', status: :ok, location: @company }
      else
        format.html { render action: 'edit' }
        format.json { render json: @company.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /companies/1
  # DELETE /companies/1.json
  def destroy
    @company.destroy
    respond_to do |format|
      format.html { redirect_to companies_url }
      format.json { head :no_content }
    end
  end

  private

  # Use callbacks to share common setup or constraints between actions.
  def set_company
    @company = Company.friendly.find(params[:id])
  end

  # Never trust parameters from the scary internet, only allow the white list through.
  def company_params
    params.require(:company).permit(:name)
  end
end
