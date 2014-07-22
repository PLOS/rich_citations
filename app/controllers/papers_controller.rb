class PapersController < ApplicationController

  def index
    if params[:doi].present? then
      redirect_to action: 'view', id: Id::Doi.extract(params[:doi])
    end
  end

  def show
    @doi = Id::Doi.extract( params[:id] )

    raise "DOI is Invalid" if @doi.blank?
    raise "Not a PLOS DOI" unless Id::Doi.is_plos_doi?(@doi)

    @paper = PaperResult.find_or_new_for_doi(@doi)
    if @paper.should_start_analysis?
      @paper.start_analysis!
      @paper.save
    end
    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@paper.doi}.js"} if !params[:inline]
        result = @paper.ready? ? @paper.result : { processing: true }
        status = @paper.ready? ? :ok : :created
        render json:result, status:status
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }

    end

  end

  def view
    @doi = params[:id]
    @journal_url = PaperResult.journal_url(@doi)
    @xml = Plos::Api.document(@doi)
    render layout: 'viewer'
  end

  def reference
    @doi = params[:id]
    @paper = PaperResult.calculate_for(params[:id])
    ref = @paper.info[:references].values.select{|r|r[:index] == params[:referenceid].to_i}.first
    render json: JSON.pretty_unparse(ref)
  end

  def interstitial
    @paper = PaperResult.calculate_for(params[:from])
    @ref = @paper.info[:references].values.select{|r|r[:index] == params[:to].to_i}.first
    render layout: 'plain'
  end
end
