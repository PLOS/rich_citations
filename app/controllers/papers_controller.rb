class PapersController < ApplicationController

  def show
    @paper = Paper.find_by_doi!( params[:id] )

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"}
        render json: @paper.references
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

  def view
    @doi = params[:id]
    @xml = Plos::Api.document(@doi)
    @paper = Paper.calculate_for(@doi)
    render layout: 'viewer'
  end
end
