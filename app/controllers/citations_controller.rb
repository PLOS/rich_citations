class CitationsController < ApplicationController

  def show
    @query = 'circadian rhythms'
    @limit = 500
  end

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

end
