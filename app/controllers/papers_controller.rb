class PapersController < ApplicationController

  def show
    @paper = Paper.find_by_doi!( params[:id] )
  end

end
