class ResultsController < ApplicationController

  def index
    @result = Result.new(
        query: 'Circadian Rhythms',
        limit: 50
    )

    @available_results = Result.order(updated_at: :desc)

    render :index
  end

  def create
    @result = Result.find_or_new( result_params )
    if @result.save
      @result.start_analysis!
      redirect_to result_path(@result.token)
    else
      render :new
    end
  end

  def show
    @result = Result.for_token( params.require(:id) )
  end

  private

  def result_params
    params.require(:result).permit(:query, :limit)
  end

end
