class ResultsController < ApplicationController

  def index
    @search_result ||= Result.new(
        query: 'Circadian Rhythms',
        limit: 50
    )
    @analyze_result ||= Result.new

    @available_results = Result.order(updated_at: :desc)

    render :index
  end

  def search
    @search_result = Result.find_or_new_for_search( search_params )
    if @search_result.save
      @search_result.start_analysis!
      redirect_to result_path(@search_result.token)

    else
      index

    end
  end

  def analyze
    @analyze_result = Result.find_or_new_for_analyze( analyze_params )
    if @analyze_result.nil?
      @analyze_result = Result.new(analyze_params)
      @analyze_result.errors.add(:query, 'must be valid')
      index

    elsif @analyze_result.save
      @analyze_result.start_analysis!
      redirect_to result_path(@analyze_result.token)

    else
      index

    end
  end

  def show
    @result = Result.for_token( params.require(:id) )

    respond_to do |format|

      format.html {
        if @result.ready?
          @sort_col  = params[:sort].to_sym
          @sort_desc = params[:dir] == 'desc'
          @citations = @result.analysis_results[:citations] || {}
          @citations = sort_citations(@citations, @sort_col, @sort_desc)
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
    options = {sort:column}
    if column == @sort_col
      options[:dir] = @sort_desc ? nil : 'desc'
    end

    view_context.link_to(text, result_path(@result.token, options))
  end
  helper_method :sort_link

  private

  def search_params
    params.require(:result).permit(:query, :limit)
  end

  def analyze_params
    params.require(:result).permit(:query)
  end

  def sort_citations(citations, column, descending)

    if column
      results = citations.sort_by { |_,v| v[column] }
      descending ? results.reverse.to_h : results.to_h
    elsif descending
      citations.to_a.reverse.to_h
    else
      # Parser ensures that citations are sorted
      citations
    end

  end

end
