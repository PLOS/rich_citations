class PapersController < ApplicationController

  def show
    @doi = Id::Doi.extract( params[:id] )

    raise "DOI is Invalid" if @doi.blank?
    raise "Not a PLOS DOI" unless Id::Doi.is_plos_doi?(@doi)

    @paper = PaperResult.find_or_new_for_doi(@doi)
    if ! @paper.ready?
      @paper.start_analysis!
      @paper.save
    end

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"}
        result = @paper.ready? ? @paper.result : { processing: true }
        status = @paper.ready? ? :ok : :created
        render json:result, status:status
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

end
