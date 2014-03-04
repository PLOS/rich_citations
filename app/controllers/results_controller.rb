class ResultsController < ApplicationController

  def index
    @result = Result.new(
        query: 'Circadian Rhythms',
        limit: 50
    )

    render :new
  end

  def create
    @result = Result.find_or_new( result_params )
    if @result.save
      redirect_to result_path(@result.token)
    else
      render :new
    end
  end

  def show
    @result = Result.for_token( params.require(:id) )
  end

  #@todo #@mro
  def search
    @query = params[:q]
    @query.strip! if @query
    @limit = params[:limit].strip
    @limit.strip! if @limit

    if @query.blank?
      flash.alert = 'Please supply a search string'
      render :show
      return
    end

    @limit = @limit.to_i
    @limit = 500 if @limit <= 0

    @results = Plos::PaperDatabase.analyze!(@query, @limit)
    @results = JSON.pretty_generate(@results) if @results.present?

    render :show
  end

  private

  def result_params
    params.require(:result).permit(:query, :limit)
  end

end
