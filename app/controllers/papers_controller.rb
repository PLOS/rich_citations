class PapersController < ApplicationController

  def show
    @paper = PaperResult.find_by_doi!( params[:id] )

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"}
        render json: @paper.result
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

end
