class PapersController < ApplicationController

  def show
    @paper = PaperResult.find_by_doi!( params[:id] )

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"} if !params[:inline]
        render json: @paper.result
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

  def view
    @doi = params[:id]
    @paper = PaperResult.calculate_for(@doi)
    @xml = Plos::Api.document(@doi)
    render layout: 'viewer'
  end

  def reference
    @doi = params[:id]
    @paper = PaperResult.calculate_for(@doi)
    ref = @paper.info[:references].values.select{|r|r[:index] == params[:referenceid].to_i}.first
    render json: JSON.pretty_unparse(ref)
  end
end
