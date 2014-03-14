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

    respond_to do |format|

      format.html {
        if @result.ready?
          @sort      = params[:sort].to_sym
          @citations = @result.analysis_results[:citations] || {}
          @citations = sort_citations(@citations, @sort)
        end
      }

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="#{@result.query}.js"}
        render json: @result.analysis_results
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }
    end

  end

  def cited
    @result = Result.for_token( params.require(:id) )
    @doi    = params[:doi]
    @cited  = @result.analysis_results[:citations][ @doi.to_sym ]
    raise ActiveRecord::RecordNotFound unless @cited

    respond_to do |format|

      format.html

      format.json {
        response.content_type = Mime::JSON
        headers['Content-Disposition'] = %Q{attachment; filename="cited #{@doi}.js"}
        render json: @cited
      }

      # format.xml  { render xml:  @result.analysis_results.to_xml }
    end

  end

  protected

  def sort_link(text, column)
    if column == @sort
      text
    else
      view_context.link_to(text, result_path(@result.token, sort:column))
    end
  end
  helper_method :sort_link

  private

  def result_params
    params.require(:result).permit(:query, :limit)
  end

  def sort_citations(citations, column)
    if column
      Hash[ citations.sort_by { |_,v| v[column] } ]
    else
      Hash[ citations.sort_by { |k,_| k  } ]
    end
  end

end
